#if UNITY_EDITOR
using System.Drawing;
using System;
using System.Collections;
using System.Collections.Generic;
using System.IO;
using UnityEngine;
using UnityEditor;

    public class RenderDocDataParserForUnity : EditorWindow
    {
        static int MeshPositionID = 0;
        static int MeshNormalID = 0;
        static int MeshTangentID = 0;
        static int MeshVertexColorID = 0;
        static int MeshUV1ID = 0;
        static int MeshUV2ID = 0;

        static bool PositionBtn = true; 
        static bool NormalnBtn = true; 
        static bool TangentnBtn = false; 
        static bool VertexColorBtn = false; 
        static bool UV1Btn = true; 
        static bool UV2Btn = false; 
        #region methods
        [MenuItem("LighadEngine/Csv to Mesh")]
        
        static void Init () 
        {
            RenderDocDataParserForUnity window = (RenderDocDataParserForUnity)EditorWindow.GetWindow (typeof (RenderDocDataParserForUnity));
            window.Show();
        }
        void OnGUI ()
        {
            EditorGUILayout.BeginVertical();

            PositionBtn = EditorGUILayout.ToggleLeft("Position",PositionBtn);
            NormalnBtn = EditorGUILayout.ToggleLeft("Normaln",NormalnBtn);
            TangentnBtn = EditorGUILayout.ToggleLeft("Tangentn",TangentnBtn);
            VertexColorBtn = EditorGUILayout.ToggleLeft("VertexColor",VertexColorBtn);
            UV1Btn = EditorGUILayout.ToggleLeft("UV1",UV1Btn);
            UV2Btn = EditorGUILayout.ToggleLeft("UV2",UV2Btn);

            if(PositionBtn)
            {
                MeshPositionID = EditorGUILayout.IntField("Position[Float3]", MeshPositionID);
            }
            if(NormalnBtn)
            {
                MeshNormalID = EditorGUILayout.IntField("Normaln[Float3]", MeshNormalID);
            }
            if(TangentnBtn)
            {
                MeshTangentID = EditorGUILayout.IntField("Tangentn[Float4]", MeshTangentID);
            }
            if(VertexColorBtn)
            {
                MeshVertexColorID = EditorGUILayout.IntField("VertexColorn[Float4]", MeshVertexColorID);
            }
            if(UV1Btn)
            {
                MeshUV1ID = EditorGUILayout.IntField("UV1[Float2]", MeshUV1ID);
            }
            if(UV2Btn)
            {
                MeshUV2ID = EditorGUILayout.IntField("UV2[Float2]", MeshUV2ID);
            }
            
            bool GetCsv = GUILayout.Button("GetCsv");
            if(GetCsv)
            {
                ParseMeshData();
            }



            EditorGUILayout.EndVertical();
            
        }
        public static void ParseMeshData()
        {
            StreamReader sr; 
            string path = LoadCSV(out sr);
            sr.ReadLine(); // pass the title
            List<string> stringDataList = new List<string>();
            
            while (!sr.EndOfStream)
            {
                string tempData = sr.ReadLine();
                tempData = tempData.Replace(" ", "");
                tempData.Replace("\r", "");
                tempData.Replace("\n", "");
                stringDataList.Add(tempData);
            }
            
            List<VertexData> vertexDataList = new List<VertexData>();

            // VTX, IDX, POSITION.x, POSITION.y, POSITION.z, NORMAL.x, NORMAL.y, NORMAL.z, TEXCOORD0.x, TEXCOORD0.y
            foreach (var stringData in stringDataList)
            {
                string[] datas = stringData.Split(',');
                VertexData vertexData = new VertexData();
                vertexData.index = int.Parse(datas[1]);
                if(PositionBtn)
                {
                    vertexData.Position = new Vector3(float.Parse(datas[MeshPositionID]), float.Parse(datas[MeshPositionID+1]), float.Parse(datas[MeshPositionID+2]));
                }
                if(NormalnBtn)
                {
                    vertexData.Normal = new Vector3(float.Parse(datas[MeshNormalID]), float.Parse(datas[MeshNormalID+1]), float.Parse(datas[MeshNormalID+2]));
                }
                if(TangentnBtn)
                {
                    vertexData.Tangent = new Vector4(float.Parse(datas[MeshTangentID]), float.Parse(datas[MeshTangentID+1]), float.Parse(datas[MeshTangentID+2]) , 1.0f);
                }
                if(VertexColorBtn)
                {
                    vertexData.Vertexcolor = new Vector4(float.Parse(datas[MeshVertexColorID]), float.Parse(datas[MeshVertexColorID+1]), float.Parse(datas[MeshVertexColorID+2]), float.Parse(datas[MeshVertexColorID+3]));
                }
                if(UV1Btn)
                {
                    vertexData.UV = new Vector2(float.Parse(datas[MeshUV1ID]), float.Parse(datas[MeshUV1ID+1]));
                }
                if(UV2Btn)
                {
                    vertexData.UV2 = new Vector2(float.Parse(datas[MeshUV2ID]), float.Parse(datas[MeshUV2ID+1]));
                }
                vertexDataList.Add(vertexData);
            }

            // construct mesh
            int maxIndex = FindMaxIndex(vertexDataList);
            int vertexArrayCount = maxIndex + 1;
            
            Vector3[] vertices = new Vector3[0];
            Vector3[] normals = new Vector3[0];
            Vector4[] tangent = new Vector4[0];
            UnityEngine.Color[] vertexcolor = new UnityEngine.Color[0];
            Vector2[] uvs = new Vector2[0];
            Vector2[] uvs2 = new Vector2[0];
            
            
            
            if(PositionBtn)
            {
                vertices = new Vector3[vertexArrayCount];
            }
            if(NormalnBtn)
            {
                normals = new Vector3[vertexArrayCount];
            }
            if(TangentnBtn)
            {
                tangent = new Vector4[vertexArrayCount];
            }
            if(VertexColorBtn)
            {
                vertexcolor = new UnityEngine.Color[vertexArrayCount];
            }

            int[] triangles = new int[vertexDataList.Count];

            if(UV1Btn)
            {
                uvs = new Vector2[vertexArrayCount];
            }
            if(UV2Btn)
            {
                uvs2 = new Vector2[vertexArrayCount];
            }

            // fill mesh data
            // ?? why hash set has not the capcity property
            Dictionary<int, int> flagDict = new Dictionary<int, int>(vertexArrayCount);;
            
            for (int i = 0; i < vertexDataList.Count; ++i)
            {
                VertexData vertexData = vertexDataList[i];
                int index = vertexData.index;
                triangles[i] = index;
                
                if (flagDict.ContainsKey(index))
                {
                    continue;
                }

                flagDict.Add(index, 1);
                
                if(PositionBtn)
                {
                    vertices[index] = vertexData.Position;
                }
                if(NormalnBtn)
                {
                    normals[index] = vertexData.Normal;
                }
                if(TangentnBtn)
                {
                    tangent[index] = vertexData.Tangent;
                }
                if(VertexColorBtn)
                {
                    vertexcolor[index] = vertexData.Vertexcolor;
                }
                if(UV1Btn)
                {
                    uvs[index] = vertexData.UV;
                }
                if(UV2Btn)
                {
                    uvs2[index] = vertexData.UV2;
                }
                
            }


            Mesh mesh = new Mesh();
            if(PositionBtn)
            {
                mesh.vertices = vertices;
            }
            if(NormalnBtn)
            {
                mesh.normals = normals;
            }
            if(TangentnBtn)
            {
                mesh.tangents = tangent;
            }
            if(VertexColorBtn)
            {
                mesh.colors = vertexcolor;
            }
            if(UV1Btn)
            {
                mesh.uv = uvs;
            }
            if(UV2Btn)
            {
                mesh.uv2 = uvs2;
            }
            mesh.triangles = triangles;
            mesh.RecalculateBounds();
            mesh.RecalculateTangents();
            AssetDatabase.CreateAsset(mesh, "Assets/" + System.IO.Path.GetFileNameWithoutExtension(path) + "_" + System.DateTime.Now.Ticks + ".mesh");
            AssetDatabase.SaveAssets();
        }

        private static int FindMaxIndex(List<VertexData> vertexDataList)
        {
            int maxIndex = 0;
            
            foreach (VertexData vertexData in vertexDataList)
            {
                int currentIndex = vertexData.index;

                if (currentIndex > maxIndex)
                {
                    maxIndex = currentIndex;
                }
            }

            return maxIndex;
        }
        
        private static string LoadCSV(out StreamReader sr)
        {
            string csvPath = EditorUtility.OpenFilePanel("select mesh data in csv", String.Empty, "csv");
            sr = new StreamReader(new FileStream(csvPath, FileMode.Open));
            return csvPath;
        }
        #endregion
        
        
        #region structs
        struct VertexData
        {
            #region fields
            public int index;
            public Vector3 Position;
            public Vector3 Normal;
            public Vector4 Tangent;
            public Vector4 Vertexcolor;
            public Vector2 UV;
            public Vector2 UV2;
            #endregion
        }
        #endregion
    }
#endif