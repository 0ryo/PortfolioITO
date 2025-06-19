import { Engine, Scene } from "@babylonjs/core";

export class CustomRenderLoop {
    private lastFrameTime = 0;
    private readonly targetFrameTime: number;

    constructor(
        private engine:Engine,
        private scene: Scene,
        targetFps = 60
    ){
        this.targetFrameTime = 1000 / targetFps;
    }

    start(){
        this.engine.runRenderLoop(() => {
            const currentTime = performance.now();
            const deltaTime = currentTime - this.lastFrameTime;

            if(deltaTime >= this.targetFrameTime){
                this.scene.render();
                this.lastFrameTime = currentTime;
            }
        });
    }

    stop(){
        this.engine.stopRenderLoop();
    }
}