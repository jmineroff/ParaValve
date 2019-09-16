using System;
using System.Collections.Generic;
using Rhino;
using Rhino.Commands;
using Rhino.Geometry;
using Rhino.Input;
using Rhino.Input.Custom;
using Rhino.DocObjects;

namespace brep_trivariate
{
    [System.Runtime.InteropServices.Guid("31f9d9ca-62db-4578-837d-68699a1b2b33")]
    public class breptrivariateCommand : Command
    {
        public breptrivariateCommand()
        {
            // Rhino only creates one instance of each command class defined in a
            // plug-in, so it is safe to store a refence in a static property.
            Instance = this;
        }

        ///<summary>The only instance of this command.</summary>
        public static breptrivariateCommand Instance
        {
            get;
            private set;
        }

        ///<returns>The command name as it appears on the Rhino command line.</returns>
        public override string EnglishName
        {
            get { return "breptrivariateCommand"; }
        }

        protected override Result RunCommand(RhinoDoc doc, RunMode mode)
        {
            /////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
            //Get one nurbs surface
            RhinoApp.WriteLine("The {0} command is under construction.", EnglishName);
            ObjRef[] objrefs;
            //var rc = RhinoGet.GetOneObject("Select surface or polysurface to mesh", false, ObjectType.Surface | ObjectType.PolysrfFilter, out objrefs);
            var rc = RhinoGet.GetMultipleObjects("Select two NURBS surfaces", false, ObjectType.Surface | ObjectType.PolysrfFilter, out objrefs);
            if (rc != Result.Success)
                return rc;
            if (objrefs == null || objrefs.Length < 1)
                return Rhino.Commands.Result.Failure;
            List<Surface> surface = new List<Surface>();

            for (int i = 0; i < objrefs.Length; i++)
            {
                Surface surf = objrefs[i].Surface();
                if (surf != null)
                    surface.Add(surf);
            }

            /////////////////////////////////////////////////////////////////////////////////////////////////////////////////
            // Surface 1 information
            var nurbs_surface0 = surface[0].ToNurbsSurface();

            //Get degree of each directions
            int u_degree0 = nurbs_surface0.Degree(0);
            int v_degree0 = nurbs_surface0.Degree(1);
            RhinoApp.WriteLine("Surface 1: u_degree: {0}, v_degree: {1}", u_degree0, v_degree0);
            //Get knot vector;
            double[] knot_u0 = new double[nurbs_surface0.KnotsU.Count];
            for (int u = 0; u < nurbs_surface0.KnotsU.Count; u++)
                knot_u0[u] = nurbs_surface0.KnotsU[u];

            double[] knot_v0 = new double[nurbs_surface0.KnotsV.Count];
            for (int v = 0; v < nurbs_surface0.KnotsV.Count; v++)
                knot_v0[v] = nurbs_surface0.KnotsV[v];
            RhinoApp.WriteLine("Surface 1: KnotsU.Count: {0}, KnotsV.Count: {1}", knot_u0.Length, knot_v0.Length);
            
            //Get Control Points (location and weight);
            var control_points0 = new ControlPoint[nurbs_surface0.Points.CountU, nurbs_surface0.Points.CountV];
            for (int u = 0; u < nurbs_surface0.Points.CountU; u++)
            {
                for (int v = 0; v < nurbs_surface0.Points.CountV; v++)
                {
                    control_points0[u, v] = nurbs_surface0.Points.GetControlPoint(u, v);
                }
            }
            RhinoApp.WriteLine("Surface 1: PointsU.Count: {0}, PointsV.Count: {1}", nurbs_surface0.Points.CountU, nurbs_surface0.Points.CountV);
            //RhinoApp.WriteLine("Control point at [0,0]: {0}, weight: {1}", control_points[0,0].Location.ToString(), control_points[0,0].Weight);

            doc.Views.Redraw();

            /////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
            //Degree
            int P, Q, R;
            P = u_degree0;
            Q = v_degree0;
            R = 1;

            int MCP, NCP, OCP;
            MCP = nurbs_surface0.Points.CountU;
            NCP = nurbs_surface0.Points.CountV;
            OCP = 2;
            // NUMBER OF NODES AND FACES, ELEMENTS
            int NNODZ, NFACE, NEL, CLOSED_U_flag, CLOSED_V_flag, CLOSED_W_flag;
            NNODZ = MCP * NCP * OCP;
            CLOSED_U_flag = 0;
            CLOSED_V_flag = 0;
            CLOSED_W_flag = 0;
            NFACE = 2 * (MCP - P) * (NCP - Q) * (1 - CLOSED_W_flag) + 2 * (NCP - Q) * (OCP - R) * (1 - CLOSED_U_flag) + 2 * (MCP - P) * (OCP - R) * (1 - CLOSED_V_flag);
            NEL = (MCP - P) * (NCP - Q) * (OCP - R);

            //write output in mesh.dat
            using (System.IO.StreamWriter file = new System.IO.StreamWriter(@"\\Mac\Dropbox\wrmorrow-2\HeartValve\NURBS\geometry\smesh.1.dat", false))
            {
                //number of spacial dimension
                file.Write("3\n");
                //degree of surface in u, v, w directions
                //file.Write("{0} {1} {2}\n", P, Q, R);
                file.Write("{0} {1}\n", P, Q);
                //control points in u, v, w directions
                //file.Write("{0} {1} {2}\n", MCP, NCP, OCP);
                file.Write("{0} {1}\n", MCP, NCP);
                //knot vectoer in u, v, w directions
                file.Write("{0} ", knot_u0[0]);
                for (int u = 0; u < nurbs_surface0.KnotsU.Count; u++)
                    file.Write("{0} ", knot_u0[u]);
                file.Write("{0} ", knot_u0[nurbs_surface0.KnotsU.Count - 1]);
                file.Write("\n");
                file.Write("{0} ", knot_v0[0]);
                for (int v = 0; v < nurbs_surface0.KnotsV.Count; v++)
                    file.Write("{0} ", knot_v0[v]);
                file.Write("{0} ", knot_v0[nurbs_surface0.KnotsV.Count - 1]);
                file.Write("\n");
                //file.Write("0 0 1 1\n");

                //3. coordinates of control points and their weight
                //control points of surface 1
                for (int v = 0; v < nurbs_surface0.Points.CountV; v++)
                {
                    for (int u = 0; u < nurbs_surface0.Points.CountU; u++)
                    {
                        file.Write("{0} {1} {2} {3}\n", control_points0[u, v].Location.X, control_points0[u, v].Location.Y, control_points0[u, v].Location.Z, control_points0[u, v].Weight);
                    }
                }
                ////control points of surface 2
                //for (int v = 0; v < nurbs_surface1.Points.CountV; v++)
                //{
                //    for (int u = 0; u < nurbs_surface1.Points.CountU; u++)
                //    {
                //        file.Write("{0} {1} {2} {3}\n", control_points1[u, v].Location.X, control_points1[u, v].Location.Y, control_points1[u, v].Location.Z, control_points1[u, v].Weight);
                //    }
                //}
                
                //4. IPER
                //for (int v = 0; v < nurbs_surface0.Points.CountV; v++)
                //{
                //    for (int u = 0; u < nurbs_surface0.Points.CountU; u++)
                //    {
                //        file.Write("{0}\n", u + v * nurbs_surface0.Points.CountU + 1);
                //    }
                //}
                //for (int v = 0; v < nurbs_surface1.Points.CountV; v++)
                //{
                //    for (int u = 0; u < nurbs_surface1.Points.CountU; u++)
                //    {
                //        file.Write("{0}\n", u + v * nurbs_surface1.Points.CountU + 1 + nurbs_surface0.Points.CountU * nurbs_surface0.Points.CountV);
                //    }
                //}
                ////5. Face information: closed_flag
                //file.Write("{0} {1} {2}\n", CLOSED_U_flag, CLOSED_V_flag, CLOSED_W_flag);

                //6. IBC for Control Points
                //for (int v = 0; v < nurbs_surface0.Points.CountV; v++)
                //{
                //    for (int u = 0; u < nurbs_surface0.Points.CountU; u++)
                //    {
                //        file.Write("0 0 0\n");
                //    }
                //}
                //for (int v = 0; v < nurbs_surface1.Points.CountV; v++)
                //{
                //    for (int u = 0; u < nurbs_surface1.Points.CountU; u++)
                //    {
                //        file.Write("0 0 0\n");
                //    }
                //}

                //7. Displacement
                //for (int v = 0; v < nurbs_surface0.Points.CountV; v++)
                //{
                //    for (int u = 0; u < nurbs_surface0.Points.CountU; u++)
                //    {
                //        file.Write("0.0 0.0 0.0\n");
                //    }
                //}
                //for (int v = 0; v < nurbs_surface1.Points.CountV; v++)
                //{
                //    for (int u = 0; u < nurbs_surface1.Points.CountU; u++)
                //    {
                //        file.Write("0.0 0.0 0.0\n");
                //    }
                //}

                //8. IBC on Face
                //for (int i = 0; i < NFACE; i++) 
                //{
                //    file.Write("0 0 0\n");
                //}

                //9. Load on Face
                //for (int i = 0; i < NFACE; i++)
                //{
                //    file.Write("0.0 0.0 0.0\n");
                //}

                //10. Body force
                //for (int i = 0; i < NEL; i++)
                //{
                //    file.Write("0.0 0.0 0.0\n");
                //}
                

                //11. Material data
                //for (int i = 0; i < NEL; i++)
                //{
                //    file.Write("0.0\n");
                //}
                file.Write("1");
                
            }



            if (objrefs.Length > 1)
            {
                /////////////////////////////////////////////////////////////////////////////////////////////////////////////////
                // Surface 2 information
                var nurbs_surface1 = surface[1].ToNurbsSurface();

                //Get degree of each directions
                int u_degree1 = nurbs_surface1.Degree(0);
                int v_degree1 = nurbs_surface1.Degree(1);
                RhinoApp.WriteLine("Surface 2: u_degree: {0}, v_degree: {1}", u_degree1, v_degree1);
                //Get knot vector;
                double[] knot_u1 = new double[nurbs_surface1.KnotsU.Count];
                for (int u = 0; u < nurbs_surface1.KnotsU.Count; u++)
                    knot_u1[u] = nurbs_surface1.KnotsU[u];

                double[] knot_v1 = new double[nurbs_surface1.KnotsV.Count];
                for (int v = 0; v < nurbs_surface1.KnotsV.Count; v++)
                    knot_v1[v] = nurbs_surface1.KnotsV[v];
                RhinoApp.WriteLine("Surface 2: KnotsU.Count: {0}, KnotsV.Count: {1}", knot_u1.Length, knot_v1.Length);

                //Get Control Points (location and weight);
                var control_points1 = new ControlPoint[nurbs_surface1.Points.CountU, nurbs_surface1.Points.CountV];
                for (int u = 0; u < nurbs_surface1.Points.CountU; u++)
                {
                    for (int v = 0; v < nurbs_surface1.Points.CountV; v++)
                    {
                        control_points1[u, v] = nurbs_surface1.Points.GetControlPoint(u, v);
                    }
                }
                RhinoApp.WriteLine("Surface 2: PointsU.Count: {0}, PointsV.Count: {1}", nurbs_surface1.Points.CountU, nurbs_surface1.Points.CountV);
                //RhinoApp.WriteLine("Control point at [0,0]: {0}, weight: {1}", control_points[0,0].Location.ToString(), control_points[0,0].Weight);
            
                //write output in mesh.dat
                using (System.IO.StreamWriter file = new System.IO.StreamWriter(@"\\Mac\Dropbox\wrmorrow-2\HeartValve\NURBS\geometry\smesh.2.dat", false))
                {
                    //number of spacial dimension
                    file.Write("3\n");
                    //degree of surface in u, v, w directions
                    //file.Write("{0} {1} {2}\n", P, Q, R);
                    file.Write("{0} {1}\n", P, Q);
                    //control points in u, v, w directions
                    //file.Write("{0} {1} {2}\n", MCP, NCP, OCP);
                    file.Write("{0} {1}\n", MCP, NCP);
                    //knot vectoer in u, v, w directions
                    file.Write("{0} ", knot_u1[0]);
                    for (int u = 0; u < nurbs_surface1.KnotsU.Count; u++)
                        file.Write("{0} ", knot_u0[u]);
                    file.Write("{0} ", knot_u0[nurbs_surface1.KnotsU.Count - 1]);
                    file.Write("\n");
                    file.Write("{0} ", knot_v1[0]);
                    for (int v = 0; v < nurbs_surface0.KnotsV.Count; v++)
                        file.Write("{0} ", knot_v1[v]);
                    file.Write("{0} ", knot_v1[nurbs_surface1.KnotsV.Count - 1]);
                    file.Write("\n");
                    //file.Write("0 0 1 1\n");

                    //3. coordinates of control points and their weight
                    //control points of surface 1
                    for (int v = 0; v < nurbs_surface1.Points.CountV; v++)
                    {
                        for (int u = 0; u < nurbs_surface1.Points.CountU; u++)
                        {
                            file.Write("{0} {1} {2} {3}\n", control_points1[u, v].Location.X, control_points1[u, v].Location.Y, control_points1[u, v].Location.Z, control_points1[u, v].Weight);
                        }
                    }
                    file.Write("1");
                }
            }

            if (objrefs.Length > 2)
            {
                /////////////////////////////////////////////////////////////////////////////////////////////////////////////////
                // Surface 3 information
                var nurbs_surface2 = surface[2].ToNurbsSurface();

                //Get degree of each directions
                int u_degree2 = nurbs_surface2.Degree(0);
                int v_degree2 = nurbs_surface2.Degree(1);
                RhinoApp.WriteLine("Surface 3: u_degree: {0}, v_degree: {1}", u_degree2, v_degree2);
                //Get knot vector;
                double[] knot_u2 = new double[nurbs_surface2.KnotsU.Count];
                for (int u = 0; u < nurbs_surface2.KnotsU.Count; u++)
                    knot_u2[u] = nurbs_surface2.KnotsU[u];

                double[] knot_v2 = new double[nurbs_surface2.KnotsV.Count];
                for (int v = 0; v < nurbs_surface2.KnotsV.Count; v++)
                    knot_v2[v] = nurbs_surface2.KnotsV[v];
                RhinoApp.WriteLine("Surface 3: KnotsU.Count: {0}, KnotsV.Count: {1}", knot_u2.Length, knot_v2.Length);

                //Get Control Points (location and weight);
                var control_points2 = new ControlPoint[nurbs_surface2.Points.CountU, nurbs_surface2.Points.CountV];
                for (int u = 0; u < nurbs_surface2.Points.CountU; u++)
                {
                    for (int v = 0; v < nurbs_surface2.Points.CountV; v++)
                    {
                        control_points2[u, v] = nurbs_surface2.Points.GetControlPoint(u, v);
                    }
                }
                RhinoApp.WriteLine("Surface 3: PointsU.Count: {0}, PointsV.Count: {1}", nurbs_surface2.Points.CountU, nurbs_surface2.Points.CountV);
                //RhinoApp.WriteLine("Control point at [0,0]: {0}, weight: {1}", control_points[0,0].Location.ToString(), control_points[0,0].Weight);

                //write output in mesh.dat
                using (System.IO.StreamWriter file = new System.IO.StreamWriter(@"\\Mac\Dropbox\wrmorrow-2\HeartValve\NURBS\geometry\smesh.3.dat", false))
                {
                    //number of spacial dimension
                    file.Write("3\n");
                    //degree of surface in u, v, w directions
                    //file.Write("{0} {1} {2}\n", P, Q, R);
                    file.Write("{0} {1}\n", P, Q);
                    //control points in u, v, w directions
                    //file.Write("{0} {1} {2}\n", MCP, NCP, OCP);
                    file.Write("{0} {1}\n", MCP, NCP);
                    //knot vectoer in u, v, w directions
                    file.Write("{0} ", knot_u2[0]);
                    for (int u = 0; u < nurbs_surface2.KnotsU.Count; u++)
                        file.Write("{0} ", knot_u2[u]);
                    file.Write("{0} ", knot_u2[nurbs_surface2.KnotsU.Count - 1]);
                    file.Write("\n");
                    file.Write("{0} ", knot_v2[0]);
                    for (int v = 0; v < nurbs_surface2.KnotsV.Count; v++)
                        file.Write("{0} ", knot_v2[v]);
                    file.Write("{0} ", knot_v2[nurbs_surface2.KnotsV.Count - 1]);
                    file.Write("\n");
                    //file.Write("0 0 1 1\n");

                    //3. coordinates of control points and their weight
                    //control points of surface 1
                    for (int v = 0; v < nurbs_surface2.Points.CountV; v++)
                    {
                        for (int u = 0; u < nurbs_surface2.Points.CountU; u++)
                        {
                            file.Write("{0} {1} {2} {3}\n", control_points2[u, v].Location.X, control_points2[u, v].Location.Y, control_points2[u, v].Location.Z, control_points2[u, v].Weight);
                        }
                    }
                    file.Write("1");
                }
            }
            return Result.Success;
        }
    }
}
