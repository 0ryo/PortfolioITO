import { 
    Scene, 
    SceneOptimizer, 
    SceneOptimizerOptions,
    HardwareScalingOptimization,
    TextureOptimization,
    LensFlaresOptimization,
    ParticlesOptimization,
    ShadowsOptimization,
    PostProcessesOptimization,
    RenderTargetsOptimization
  } from "@babylonjs/core";
  
  export function setupSceneOptimization(scene: Scene) {
    // 基本的な最適化オプションを作成
    const options = new SceneOptimizerOptions(60); // targetFrameRate = 60
  
    // 最適化の優先順位を設定
    options.optimizations = [
      new HardwareScalingOptimization(0, 1), // priority = 0, maximumScale = 1
      new TextureOptimization(1, 256), // priority = 1, maximumSize = 256
      new LensFlaresOptimization(2), // priority = 2
      new ParticlesOptimization(3), // priority = 3
      new ShadowsOptimization(4), // priority = 4
      new PostProcessesOptimization(5), // priority = 5
      new RenderTargetsOptimization(6) // priority = 6
    ];
  
    // ドローコールを減らすための追加設定
    scene.skipPointerMovePicking = true;
    scene.blockMaterialDirtyMechanism = true;
  
    // メッシュのインスタンス化を有効化
    scene.clearCachedVertexData();
    scene.enableGeometryBufferRenderer();
  
    // バッチ処理の最適化
    scene.skipFrustumClipping = true;
    scene.useRightHandedSystem = true;
  
    // オプティマイザーの適用と開始
    const optimizer = new SceneOptimizer(scene, options);
    optimizer.start();
  
    // デバッグ用：最適化の進行状況をコンソールに表示
    optimizer.onNewOptimizationAppliedObservable.add((optim) => {
      console.log("Optimization applied:", optim.getDescription());
    });
  
    optimizer.onFailureObservable.add(() => {
      console.warn("Optimization failed to reach target frame rate");
    });
  
    return optimizer;
  }
  