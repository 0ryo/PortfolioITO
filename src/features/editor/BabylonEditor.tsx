import {
  Engine,
  Scene,
  SceneLoader,
  GizmoManager,
  Nullable,
  CubeTexture,
  PBRMaterial
} from "@babylonjs/core"
import "@babylonjs/loaders/glTF"
import "@babylonjs/loaders/OBJ"
import "@babylonjs/loaders/STL"
import "@babylonjs/core/Loading/Plugins/babylonFileLoader"
import { VStack, Text, HStack, Progress } from "@chakra-ui/react"
import { AddIcon } from "@chakra-ui/icons"
import React, { useEffect, useMemo, useRef, useState } from "react"
import Div100vh from "react-div-100vh"
import { useRecoilState } from "recoil"
import useAssetLoad from "./hooks/useAssetLoad"
import { meshListState } from "../../globalStates/atoms/meshListState"

import InputFileButton from "./components/elements/button/InputFIleButton"
import FloatingControlPanel from "./components/elements/panel/FloatingControlPanel"
import getMeshData from "./babylonLogic/GetMeshData"
import { SceneMeshData } from "photon-babylon"
import { onEditorRendered, onEditorReady } from "./babylonLogic/Common"
import Inspector from "./components/layouts/inspector/Inspector"


import { CustomRenderLoop } from "./babylonLogic/RenderLoop"
import { setupSceneOptimization } from "./babylonLogic/SceneOptimizer"

import { ButtonGroup, Button } from "@chakra-ui/react"; //ButtonGroupとButtonを追加

const ENGINE_OPTIONS = {
  deterministicLockStep: true,
  lockstepMaxSteps: 4,
  targetFps: 60
}as const;

const BabylonEditor = () => {
  // EditorScene eventListener
  const onRender = onEditorRendered
  const onSceneReady = onEditorReady

  // Engine config
  const antialias = true
  const adaptToDeviceRatio = true
  const sceneOptions = undefined


  // Canvas state
  const renderCanvas = useRef<Nullable<HTMLCanvasElement>>(null)
  const [canvasReady, setCanvasReady] = useState(false)

  // 3D scene state
  const [gizmoManager, setGizmoManager] = useState<GizmoManager>()
  const [meshList, setMeshList] = useRecoilState(meshListState)

  const [currentLOD, setCurrentLOD ] = useState<number>(0); //0:High, 1:Medium, 2:Low

  //ローディング状態と進捗率を管理するState
  const [isLoading, setIsLoading] = useState<boolean>(false);
  const [isDracoLoading, setIsDracoLoading] = useState<boolean>(false);
  const [loadingProgress, setLoadingProgress] = useState<number>(0);

  // Babylon Engine & Scene variable
  const engine = useMemo((): Engine | undefined => {
    if (canvasReady) {
      return new Engine(
        renderCanvas.current,
        antialias,
        ENGINE_OPTIONS,
        adaptToDeviceRatio
      )
    }
    return undefined
  }, [adaptToDeviceRatio, antialias, canvasReady])
  const scene = useMemo((): Scene | undefined => {
    if (engine) {
      return new Scene(engine, sceneOptions)
    }
    return undefined
  }, [engine, sceneOptions])

  // EditorScene common setup
  useEffect(() => {
    if (engine && scene) {
      //カスタムレンダリングループの適用
      const renderLoop = new CustomRenderLoop(engine, scene, 60);

      //シーン最適化の適用
      setupSceneOptimization(scene);

      renderLoop.start();

      const resize = () => {
        scene.getEngine().resize()
      }
      if (window) {
        window.addEventListener("resize", resize)
      }

      const _gizmoManager = new GizmoManager(scene)
      setGizmoManager(_gizmoManager)

      scene.onNewMeshAddedObservable.add(() => {
        const meshes = scene.rootNodes
        setMeshList((item) => {
          const value = { ...item }
          const meshData: SceneMeshData = getMeshData(meshes)
          Object.keys(meshData).forEach((key) => {
            value[key] = meshData[key]
          })
          return value
        })
      })
      onSceneReady(scene, _gizmoManager)
      SceneLoader.OnPluginActivatedObservable.add((plugin) => {
        console.log(`Plugin activated: ${plugin.name}`);
      });

      scene.createDefaultEnvironment({
        createGround: false,
        createSkybox: false,
      });
      if (!scene.environmentTexture) {
        // 変更点: .env ファイルから環境テクスチャを作成
        const envTexture = CubeTexture.CreateFromPrefilteredData(
          "./environment.env", // .env ファイルのパス
          scene // scene を渡す
        );

      scene.environmentTexture = envTexture;
      }
      return () => {
        if (window) {
          window.removeEventListener("resize", resize)
        }
      }
    }
  }, [renderCanvas, scene, engine, onRender, onSceneReady, setMeshList]);

  // EditorScene import feature logic
  const { handleSingle3dFileInput, assetUrl, assetType } = useAssetLoad(scene, setIsLoading, setLoadingProgress, setIsDracoLoading)
  useEffect(() => {
    const Load3dData = async (scene: Scene, url: string, type: string) => {
      try {
        await SceneLoader.AppendAsync(
          url,
          undefined,
          scene,
          (progress) => {
            //進行状況の表示
            console.log(
              `Loading... ${(progress.loaded / progress.total) * 100}%`
            );
          },
          type
        );
        //マテリアルに環境テクスチャを適用
        scene.meshes.forEach((mesh) => {
          if (mesh.material) {
            if (mesh.material instanceof PBRMaterial) { // 型ガード
              // PBRマテリアルの場合、環境テクスチャを設定
              if (!mesh.material.reflectionTexture) {
                // 型アサーションで、environmentTextureが存在することを明示
                (mesh.material as PBRMaterial).reflectionTexture = scene.environmentTexture;
              }
            } else {
              // PBRマテリアル以外の場合、警告を表示
              console.warn(
                "Loaded model does not use PBR materials. Consider using PBR materials for better results with environment lighting."
              );
            }
          }
        });
      } catch (error) {
        console.error("Error loading 3D data:", error);
      }
    };

    if (assetUrl == "") return;
    if (scene) {
      Load3dData(scene, assetUrl, assetType).then(() => {
        // do nothing | ファイル読み込み後の振る舞い
        console.log("end"); // エラー確認用のログ
      })
    }
  }, [assetUrl, assetType, scene])
  useEffect(() => {
    if(scene) {
      const highModel = scene.getMeshByName("highModel");
      const lowModel = scene.getMeshByName("lowModel");

      if(highModel && lowModel) {
        if(currentLOD === 0) {
          highModel.setEnabled(true);//Highモデルを表示
        } else if (currentLOD === 1) {
          highModel.setEnabled(true);//Mediumモデルを表示
        } else {
          highModel.setEnabled(false);//Lowモデルを表示
        }
      }
    }
  }, [currentLOD, scene]);

  return (
    <Div100vh
      style={{
        overflow: "hidden",
      }}
    >
      <FloatingControlPanel>
        <VStack alignItems="start" maxH="90vh">
          <HStack mt={2} mx={4}>
            <Text>Inspector</Text>
            <InputFileButton
              name="FILE"
              labelText="インポート"
              onChange={(e) => {
                handleSingle3dFileInput(e)
                e.target.value = ""
              }}
              size="xs"
            >
              <AddIcon />
            </InputFileButton>
          </HStack>

          {isLoading && (
            <Progress
              width="100%"
              value={loadingProgress}
              isIndeterminate={isDracoLoading}
            />
          )}
          {isLoading && isDracoLoading && <Text>Draco圧縮中 : {loadingProgress}%</Text>}
          {isLoading && !isDracoLoading && <Text>モデルをロード中 : {loadingProgress}%</Text>}

          {/* LOD切り替えボタン */}
          <ButtonGroup>
            <Button size="xs" colorScheme={currentLOD === 0 ? "blue" : undefined} onClick={() => setCurrentLOD(0)}>High</Button>
            <Button size="xs" colorScheme={currentLOD === 1 ? "blue" : undefined} onClick={() => setCurrentLOD(1)}>Medium</Button>
            <Button size="xs" colorScheme={currentLOD === 2 ? "blue" : undefined} onClick={() => setCurrentLOD(2)}>Low</Button>
          </ButtonGroup>

          <Inspector
            meshList={meshList}
            scene={scene}
            onClickMeshItem={(meshItem) => {
              const id = meshItem.uid
              const target = scene?.getMeshByUniqueId(id)
              if (target) gizmoManager?.attachToMesh(target)
            }}
            onClickNodeItem={(nodeItem) => {
              const id = nodeItem.uid
              const target = scene?.getTransformNodeByUniqueId(id)
              if (target) gizmoManager?.attachToNode(target)
            }}
          />
        </VStack>
      </FloatingControlPanel>
      <canvas
        ref={(view) => {
          renderCanvas.current = view
          setCanvasReady(true)
        }}
        style={{
          width: "100%",
          height: "100%",
          outline: "none",
        }}
      />
    </Div100vh>
  )
}

export default BabylonEditor
