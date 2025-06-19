import { ChangeEventHandler, useState } from "react";
import { Scene } from "@babylonjs/core";
import { loadAndDivideData } from "../babylonLogic/DataDivider";

const useAssetLoad = (
  scene?: Scene,
  setIsLoading?: (isLoading: boolean) => void,
  setLoadingProgress?: (progress: number) => void,
  setIsDracoLoading?: (isDracoLoading: boolean) => void
) => {
  const [assetUrl, setAssetUrl] = useState("");
  const [assetType, setAssetType] = useState("");

  const handleSingle3dFileInput: ChangeEventHandler<HTMLInputElement> = (
    event
  ) => {
    if (!event.target.files?.length || !scene) {
      return;
    }

    // 既存のオブジェクトを削除
    const box1 = scene.getMeshByName("box1");
    if (box1) {
      box1.dispose();
    }

    const highModel = scene.getMeshByName("highModel");
    if (highModel) {
      highModel.dispose();
    }

    const lowModel = scene.getMeshByName("lowModel");
    if (lowModel) {
      lowModel.dispose();
    }

    // インスタンス化されたメッシュを削除
    scene.meshes.forEach((mesh) => {
      if (mesh.name.endsWith("_instance")) {
        mesh.dispose();
      }
    });

    const file = event.target.files[0];
    const type = file.name.split(".").at(-1);

    if (type == undefined) {
      console.warn("対応していない形式のファイルです", file.name);
      return;
    } else if (!["glb", "gltf", "obj", "stl"].includes(type)) {
      console.warn("対応していない形式のファイルです", file.name);
      return;
    }

    const fileURL = URL.createObjectURL(file);
    setAssetUrl(fileURL);
    setAssetType(`.${type}`);

    try {
      loadAndDivideData(
        scene,
        fileURL,
        `.${type}`,
        512 * 512,
        file.size,
        (progress) => {
          // ロードの進捗状況を更新
          if (setLoadingProgress) {
            setLoadingProgress(progress);
          }
        },
        () => {
          // ロード開始時に isLoading を true に設定
          if (setIsLoading) {
            setIsLoading(true);
          }
        },
        () => {
          // ロード完了時に isLoading を false に設定
          if (setIsLoading) {
            setIsLoading(false);
          }
        },
        (isDracoLoading) => {
          // Draco圧縮の状態を更新
          if (setIsDracoLoading) {
            setIsDracoLoading(isDracoLoading);
          }
        }
      );
    } catch (error) {
      console.error("Error handling file input:", error);
    }
  };

  return { handleSingle3dFileInput, assetUrl, assetType };
};

export default useAssetLoad;