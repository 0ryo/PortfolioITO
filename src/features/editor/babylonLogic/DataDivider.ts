// #features/editor/babylonLogic/DataDivider.ts

import {
  Scene,
  SceneLoader,
  AssetContainer,
  Mesh,
  AbstractMesh,
  StandardMaterial,
  Color3,
  SimplificationQueue,
  SimplificationType,
  InstancedMesh,
  DracoCompression
 } from "@babylonjs/core";
import { IGLTFLoaderData } from "@babylonjs/loaders/glTF/glTFFileLoader";
//import "@babylonjs/loaders/glTF/2.0/Extensions/DracoCompression";
import '@babylonjs/loaders/glTF/2.0/Extensions/KHR_draco_mesh_compression';


/**
 * glTFファイルのバイナリデータを分割する
 * @param gltfData glTFファイルのデータ
 * @param chunkSize 分割するチャンクサイズ
 * @returns 分割されたバイナリデータの配列
 */
export const divideBinaryData = (gltfData: any, chunkSize: number): ArrayBuffer[] => {
    const binaryData = gltfData.buffers[0].data;
    const chunks = [];
    for (let i = 0; i < binaryData.byteLength; i += chunkSize) {
        chunks.push(binaryData.slice(i, i + chunkSize));
    }
    return chunks;
};

const createHighModel = async (
    scene: Scene,
    gltfData: IGLTFLoaderData,
): Promise<Mesh> => {
    const highModelContainer = new AssetContainer(scene);
    const clonedGltfData = JSON.parse(JSON.stringify(gltfData));
    const container = await SceneLoader.LoadAssetContainerAsync("", "data:" + JSON.stringify(clonedGltfData), scene);

    const highModel = new Mesh("highModel", scene);
    container.meshes.forEach((mesh) => {
        if (mesh !== highModel) {
            mesh.parent = highModel;
        }
    });

    highModelContainer.meshes.push(highModel);
    highModelContainer.addAllToScene();
    return highModel;
};

const createLowModel = async (
    scene: Scene,
    gltfData: IGLTFLoaderData,
): Promise<Mesh> => {
    const lowModelContainer = new AssetContainer(scene);
    const clonedGltfData = JSON.parse(JSON.stringify(gltfData));
    const container = await SceneLoader.LoadAssetContainerAsync("", "data:" + JSON.stringify(clonedGltfData), scene);
    
    const targetMeshCount = Math.max(1, Math.floor(container.meshes.length / 3));
    const lowModel = new Mesh("lowModel", scene);

    for (let i = 0; i < targetMeshCount; i++) {
        const meshIndex = i * 3;
        if (meshIndex < container.meshes.length) {
            const mesh = container.meshes[meshIndex];
            if (mesh !== lowModel) {
                mesh.parent = lowModel;
            }
        }
    }

    lowModelContainer.meshes.push(lowModel);
    lowModelContainer.addAllToScene();
    return lowModel;
};

//インスタンシングをチェックする関数
const checkForInstances = (meshes: AbstractMesh[]): [Mesh[], AbstractMesh[][]] => {
  const uniqueMeshes: Mesh[] = [];
  const instances: AbstractMesh[][] = [];

  meshes.forEach((mesh) => {
    if (!(mesh instanceof Mesh) || mesh.name.includes("highModel") || mesh.name.includes("lowModel")) return;

    const existingMesh = uniqueMeshes.find(
      (uniqueMesh) =>
        uniqueMesh.geometry === mesh.geometry &&
        uniqueMesh.material === mesh.material
    );

    if (existingMesh) {
      const existingMeshInstances = instances.find((instanceGroup) =>
        instanceGroup.includes(existingMesh)
      );
      if (existingMeshInstances) {
        existingMeshInstances.push(mesh);
      } else {
        instances.push([existingMesh, mesh]);
      }
    } else {
      uniqueMeshes.push(mesh as Mesh);
    }
  });

  return [uniqueMeshes, instances];
};

/**
 * 3Dデータを小さな単位に分割してロードする
 * @param scene Babylon.jsのシーン
 * @param url アセットのURL
 * @param type アセットのタイプ（例：".glb", ".gltf"）
 * @param chunkSize チャンクサイズ（バイト単位）
 * @param fileSize ファイルサイズ（バイト単位）
 * @param onProgress ロードの進捗状況を通知するコールバック関数
 * @param onLoadStart ロード開始時に呼び出されるコールバック関数
 * @param onLoadEnd ロード完了時に呼び出されるコールバック関数
 */
export const loadAndDivideData = async (
    scene: Scene,
    url: string,
    type: string,
    chunkSize: number,
    fileSize: number,
    onProgress?: (progress: number) => void,
    onLoadStart?: () => void,
    onLoadEnd?: () => void,
    onDracoStart?: (isDracoLoading: boolean) => void
  ) => {
    try {
      if (type === ".glb" || type === ".gltf") {
        //Dracoデコーダーのパスを指定
        DracoCompression.Configuration = {
          decoder: {
            wasmUrl: "../../../../public/draco_wasm_wrapper.js",
            wasmBinaryUrl: "../../../../public/draco_decoder.wasm",
            fallbackUrl: "../../../../draco_decoder.js",
          },
        };

        const useDraco = fileSize > 100 * 1024 * 1024; // 100MB以上ならDraco圧縮を使用
        if (useDraco) {
          console.log("Applying Draco compression");
          if(onDracoStart) {
            onDracoStart(true); //Draco圧縮開始
          }
        } else {
          if(onDracoStart) {
            onDracoStart(false); //Draco圧縮なし
          }
        }

        if (onLoadStart){
          onLoadStart();
        }

          const container = await SceneLoader.LoadAssetContainerAsync(
            url,
            "",
            scene,
            (event) => {
              if (onProgress){
                const progress = useDraco ? (event.loaded / event.total) * 0.5 : (event.loaded / event.total) * 100;
              }
            },
            useDraco && type === ".glb" ? ".gltf" : type
          );

          //Draco圧縮が完了したら、onDracoStartをfalseに設定
          if (useDraco) {
            if(onDracoStart) {
              onDracoStart(false);
            }

            //残りの50%のプログレスバーの進行を記録
            if (onProgress){
              onProgress(50);
            }
            const remainingProgress = { loaded: 0, total: 100 };

            const updateProgress = () => {
              const progress = 50 + (remainingProgress.loaded / remainingProgress.total) * 50;
              if (onProgress){
                onProgress(Math.round(progress));
              }
            };

            const intercalId = setInterval(() => {
              remainingProgress.loaded = Math.min(
                remainingProgress.loaded = 1,
                remainingProgress.total
              );
              updateProgress();

              if(remainingProgress.loaded >= remainingProgress.total) {
                clearInterval(intercalId);
              }
            }, 100);
          }

          const gltfData = (container as any).gltf;

          if (gltfData && gltfData.buffers && gltfData.buffers[0]) {
            const chunks = divideBinaryData(gltfData, chunkSize);
                //チャンクをawaitを使って順次処理
            for (let i = 0; i < chunks.length; i++) {
              gltfData.buffers[0].data = chunks[i];
              //LoadAssetContainerAsyncの第二引数にデータを与えることでシーンへの追加を確実に完了させる
              await SceneLoader.AppendAsync("", "data:" + JSON.stringify(gltfData), scene);
            }
            const highModel = await createHighModel(scene, gltfData);
            const lowModel = await createLowModel(scene, gltfData);

            //LOD情報を追加
            highModel.addLODLevel(5, null);
            highModel.addLODLevel(15, lowModel);
            lowModel.setEnabled(false);

            // インスタンシングを適用
            const [uniqueMeshes, instanceGroups] = checkForInstances(
              highModel.getChildMeshes()
            );
          instanceGroups.forEach((instanceGroup) => {
            const master = instanceGroup[0] as Mesh;
            const material = master.material;
            const geometry = master.geometry;
            if(material && geometry){
              //新しいMeshを作成
              const newMesh = new Mesh(master.name, scene);

              //GeometryをMeshに割り当て
              master.geometry.applyToMesh(newMesh);

              //マテリアルを新しいメッシュに適用
              newMesh.material = master.material;
              for (let i = 1; i < instanceGroup.length; i++) {
                const instance = (instanceGroup[i] as Mesh).createInstance(`${instanceGroup[i].name}_instance`);
                instance.parent = newMesh;
              }
              master.dispose();
            }
          });
          } else {
            console.warn("Invalid glTF data or missing binary buffer.");
          }
        } else if (type === ".obj") { //obj形式の対応
          const meshes = await SceneLoader.ImportMeshAsync("", url, "", scene);

          const highModel = new Mesh("highModel", scene);
          const lowModel = new Mesh("lowModel", scene);

          for (const mesh of meshes.meshes) {
            if (mesh !== highModel && mesh !== lowModel) {
              const highMesh = mesh.clone(`${mesh.name}_high`, highModel) as Mesh;
              const lowMesh = mesh.clone(`${mesh.name}_low`, lowModel) as Mesh;

              if (lowMesh) {
                const vertexCount = lowMesh.getTotalVertices(); // 簡略化前の頂点数を取得
                lowMesh.simplify(
                  [{ quality: 0.5, distance: 10 }],
                  false,
                  SimplificationType.QUADRATIC,
                  () => {// コールバック関数を追加
                    console.log(
                      `Simplified mesh ${lowMesh.name} from ${vertexCount} to ${lowMesh.getTotalVertices()} vertices`
                    );
                  }
                );
              }
            }
          }
  
          //LOD情報を追加
          highModel.addLODLevel(5, null);
          highModel.addLODLevel(15, lowModel);
          lowModel.setEnabled(false);

          // 変更点: インスタンシングを適用
        const [uniqueMeshes, instanceGroups] = checkForInstances(highModel.getChildMeshes());
        instanceGroups.forEach((instanceGroup) => {
          const master = instanceGroup[0] as Mesh;
          const material = master.material;
          const geometry = master.geometry;
          if(material && geometry){
            // 変更点: 新しいMeshを作成
            const newMesh = new Mesh(master.name, scene);

            // 変更点: GeometryをMeshに割り当て
            master.geometry.applyToMesh(newMesh);

            // 変更点: マテリアルを新しいメッシュに適用
            newMesh.material = master.material;
            for (let i = 1; i < instanceGroup.length; i++) {
              const instance = (instanceGroup[i] as Mesh).createInstance(`${instanceGroup[i].name}_instance`);
              instance.parent = newMesh;
            }
            master.dispose();
          }
        });
  
      }else {
        // その他の形式の処理（例：.obj, .stl, .fbx）
        // 変更点: エラー発生を検知できるように修正
        await SceneLoader.ImportMeshAsync("", url, "", scene)
        .then(() => {
          console.log("Successfully loaded mesh from:", url);
        })
        .catch((error) => {
          console.error("Error loading mesh:", error);
        });
      }
    } catch (error) {
      console.error("Error loading and dividing data:", error);
    } finally {
      //ロード完了を通知
      if (onLoadEnd){
        onLoadEnd();
      }
    }
  };