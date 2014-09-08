package {
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.display.Sprite;
	import flash.display.Stage3D;
	import flash.display.StageAlign;
	import flash.display.StageScaleMode;
	import flash.display3D.Context3D;
	import flash.display3D.Context3DBlendFactor;
	import flash.display3D.Context3DCompareMode;
	import flash.display3D.Context3DProgramType;
	import flash.display3D.Context3DTextureFormat;
	import flash.display3D.Context3DVertexBufferFormat;
	import flash.display3D.Program3D;
	import flash.display3D.textures.Texture;
	import flash.events.Event;
	import flash.events.KeyboardEvent;
	import flash.geom.Matrix;
	import flash.geom.Matrix3D;
	import flash.geom.Vector3D;
	import flash.text.TextField;
	import flash.text.TextFieldAutoSize;
	import flash.text.TextFormat;
	import flash.utils.getTimer;

	[SWF(frameRate=60, width=1200, height=800)]
	public class Main extends Sprite {

		/* TEXTURES: Pure AS3 and Flex version:
		 * if you are using Adobe Flash CS5
		 * comment out the following: */
		[Embed(source="../assets/dark_ship.png")]
		private var myTextureBitmap:Class;
		private var myTextureData:Bitmap = new myTextureBitmap();
		[Embed(source="../assets/terrain_texture.jpg")]
		private var terrainTextureBitmap:Class;
		private var terrainTextureData:Bitmap = new terrainTextureBitmap();

		// The Stage3d Texture that uses the above myTextureData
		private var myTexture:Texture;
		private var terrainTexture:Texture;

		// The terrain mesh data
		[Embed(source="../assets/terrain.obj", mimeType="application/octet-stream")]
		private var terrainObjData:Class;
		private var terrainMesh:Stage3dObjParser;

		// tiny particles
		[Embed(source="../assets/randomParticleCluste", mimeType="application/octet-stream")]
		private var randomParticleClusterData:Class;
		private var randomParticlesMesh:Stage3dObjParser;

		[Embed(source="../assets/roundPuffCluster", mimeType="application/octet-stream")]
		private var roundPuffData:Class;
		private var roundPuffMesh:Stage3dObjParser;

		[Embed(source="../assets/cube.obj", mimeType="application/octet-stream")]
		private var cubeObjData:Class;
		private var cubeMesh:Stage3dObjParser;

		[Embed(source="../assets/sphere.obj", mimeType="application/octet-stream")]
		private var sphereObjData:Class;
		private var sphereMesh:Stage3dObjParser;

		[Embed(source="../assets/ship.obj", mimeType="application/octet-stream")]
		private var shipObjData:Class;
		private var shipMesh:Stage3dObjParser;

		[Embed(source="../assets/leaf.png")]
		private var leafData:Class;
		private var leafBmp:Bitmap = new leafData();

		[Embed(source="../assets/fire.jpg")]
		private var fireData:Class;
		private var fireBmp:Bitmap = new fireData();

		[Embed(source="../assets/lensFlare.jpg")]
		private var lensFlareData:Class;
		private var lensFlareBmp:Bitmap = new lensFlareData();

		[Embed(source="../assets/glow.jpg")]
		private var glowData:Class;
		private var glowBmp:Bitmap = new glowData();

		[Embed(source="../assets/smoke.jpg")]
		private var smokeData:Class;
		private var smokeBmp:Bitmap = new smokeData();

		// used by the GUI
		private var fpsLast:uint = getTimer();
		private var fpsTicks:uint = 0;
		private var fpsTf:TextField;
		private var scoreTf:TextField;
		private var score:uint = 0;
		// constants used during inits
		private const swfWidth:int = 1200;
		private const swfHeight:int = 800;
		// for this demo, ensure ALL textures are 512x512
		private const textureSize:int = 512;
		// the 3d graphics window on the stage
		private var context3D:Context3D;
		// the compiled shaders used to render our mesh
		private var shaderProgram1:Program3D;
		// matrices that affect the mesh location and camera angles
		private var projectionmatrix:PerspectiveMatrix3D = new PerspectiveMatrix3D();
		private var modelmatrix:Matrix3D = new Matrix3D();
		private var viewmatrix:Matrix3D = new Matrix3D();
		private var terrainviewmatrix:Matrix3D = new Matrix3D();
		private var modelViewProjection:Matrix3D = new Matrix3D();
		// a simple frame counter used for animation
		private var t:Number = 0;

		// Points to whatever the current mesh is
		private var myMesh:Stage3dObjParser;

		// The Stage3d Textures that use the above
		private var leafTexture:Texture;
		private var fireTexture:Texture;
		private var lensFlareTexture:Texture;
		private var glowTexture:Texture;
		private var smokeTexture:Texture;

		// available blend/texture/mesh
		private var blendNumMax:int = 11;
		private var blendNum:int = -1;
		private var texNum:int = -1;
		private var texNumMax:int = 4;
		private var meshNum:int = -1;
		private var meshNumMax:int = 4;

		// used by the GUI
		private var label1:TextField;
		private var label2:TextField;
		private var label3:TextField;

		public function Main() {
			if (stage != null) {
				init();
			} else {
				addEventListener(Event.ADDED_TO_STAGE, init);
			}
		}

		//--------------------------------------------------------------------------
		//   							PUBLIC METHODS
		//--------------------------------------------------------------------------
		//--------------------------------------------------------------------------
		//   					  PRIVATE\PROTECTED METHODS
		//--------------------------------------------------------------------------
		private function init(e:Event = null):void {
			if (hasEventListener(Event.ADDED_TO_STAGE)) {
				removeEventListener(Event.ADDED_TO_STAGE, init);
			}

			// class constructor - sets up the stage
			stage.scaleMode = StageScaleMode.NO_SCALE;
			stage.align = StageAlign.TOP_LEFT;
			// add some text labels
			initGUI();
			// and request a context3D from Stage3d
			stage.stage3Ds[0].addEventListener(Event.CONTEXT3D_CREATE, onContext3DCreate);
			stage.stage3Ds[0].requestContext3D();

			stage.addEventListener(KeyboardEvent.KEY_DOWN, keyPressed);
		}

		private function keyPressed(event:KeyboardEvent):void {
			switch (event.charCode) {
				case 98: // the b key
					nextBlendmode();
					break;
				case 109: // the m key
					nextMesh();
					break;
				case 116: // the t key
					nextTexture();
					break;
			}
		}

		private function setBlendmode():void {
			// All possible blendmodes:
			// Context3DBlendFactor.DESTINATION_ALPHA
			// Context3DBlendFactor.DESTINATION_COLOR
			// Context3DBlendFactor.ONE
			// Context3DBlendFactor.ONE_MINUS_DESTINATION_ALPHA
			// Context3DBlendFactor.ONE_MINUS_DESTINATION_COLOR
			// Context3DBlendFactor.ONE_MINUS_SOURCE_ALPHA
			// Context3DBlendFactor.ONE_MINUS_SOURCE_COLOR
			// Context3DBlendFactor.SOURCE_ALPHA
			// Context3DBlendFactor.SOURCE_COLOR
			// Context3DBlendFactor.ZERO
			switch (blendNum) {
				case 0:
					// the default: nice for opaque textures
					context3D.setBlendFactors(Context3DBlendFactor.ONE, Context3DBlendFactor.ZERO);
					break;
				case 1:
					// perfect for transparent textures
					// like foliage/fences/fonts
					context3D.setBlendFactors(Context3DBlendFactor.SOURCE_ALPHA, Context3DBlendFactor.ONE_MINUS_SOURCE_ALPHA);
					break;
				case 2:
					// perfect to make it lighten the scene only
					// (black is not drawn)
					context3D.setBlendFactors(Context3DBlendFactor.SOURCE_COLOR, Context3DBlendFactor.ONE);
					break;
				case 3:
					// just lightens the scene - great for particles
					context3D.setBlendFactors(Context3DBlendFactor.ONE, Context3DBlendFactor.ONE);
					break;
				case 4:
					// perfect for when you want to darken only (smoke, etc)
					context3D.setBlendFactors(Context3DBlendFactor.DESTINATION_COLOR, Context3DBlendFactor.ZERO);
					break;

				case 5:
					context3D.setBlendFactors(Context3DBlendFactor.ZERO, Context3DBlendFactor.SOURCE_COLOR);
					break;

				case 6:
					context3D.setBlendFactors(Context3DBlendFactor.DESTINATION_COLOR, Context3DBlendFactor.SOURCE_COLOR);
					break;

				case 7:
					context3D.setBlendFactors(Context3DBlendFactor.ONE, Context3DBlendFactor.ONE_MINUS_SOURCE_COLOR);
					break;

				case 8:
					context3D.setBlendFactors(Context3DBlendFactor.ZERO, Context3DBlendFactor.ONE_MINUS_DESTINATION_COLOR);
					break;

				case 9:
					context3D.setBlendFactors(Context3DBlendFactor.SOURCE_ALPHA, Context3DBlendFactor.DESTINATION_COLOR);
					break;

				case 10:
					context3D.setBlendFactors(Context3DBlendFactor.DESTINATION_COLOR, Context3DBlendFactor.ONE_MINUS_SOURCE_COLOR);
					break;

				case 11:
					context3D.setBlendFactors(Context3DBlendFactor.ZERO, Context3DBlendFactor.ONE_MINUS_SOURCE_ALPHA);
					break;
			}
		}

		private function nextBlendmode():void {
			blendNum++;
			if (blendNum > blendNumMax) blendNum = 0;
			switch (blendNum) {
				case 0:
					label1.text = '[B] ONE, ZERO';
					break;
				case 1:
					label1.text = '[B] SOURCE_ALPHA, ONE_MINUS_SOURCE_ALPHA => ALPHA: preserves transprency';
					break;
				case 2:
					label1.text = '[B] SOURCE_COLOR, ONE';
					break;
				case 3:
					label1.text = '[B] ONE, ONE => ADD';
					break;
				case 4:
					label1.text = '[B] DESTINATION_COLOR, ZERO';
					break;
				case 5:
					label1.text = "[B] ZERO, SOURCE_COLOR (Multiplicative Blending)";
					break;
				case 6:
					label1.text = "[B] ZERO, SOURCE_COLOR (2X Multiplicative Blending)";
					break;
				case 7:
					label1.text = "[B] ONE, ONE_MINUS_SOURCE_COLOR (NEGATIVE) => screen";
					break;
				case 8:
					label1.text = "[B] ZERO, ONE_MINUS_DESTINATION_COLOR => SHADOW: only keeps the opaque shape, should be combined with a Colortransform"
					break;
				case 9:
					label1.text = "[B] SOURCE_ALPHA, DESTINATION_COLOR => HARDLIGHT"
					break;
				case 10:
					label1.text = "[B] DESTINATION_COLOR, ONE_MINUS_SOURCE_COLOR => Starling multiply"
					break;
				case 11:
					label1.text = "[B] ZERO, ONE_MINUS_SOURCE_ALPHA => Starling erase"
					break;
			}
		}

		private function nextTexture():void {
			texNum++;
			if (texNum > texNumMax) texNum = 0;
			switch (texNum) {
				case 0:
					label2.text = '[T] Transparent Leaf Texture';
					break;
				case 1:
					label2.text = '[T] Fire Texture';
					break;
				case 2:
					label2.text = '[T] Lens Flare Texture';
					break;
				case 3:
					label2.text = '[T] Glow Texture';
					break;
				case 4:
					label2.text = '[T] Smoke Texture';
					break;
			}
		}

		private function nextMesh():void {
			meshNum++;
			if (meshNum > meshNumMax) meshNum = 0;
			switch (meshNum) {
				case 0:
					label3.text = '[M] Random Particle Cluster';
					break;
				case 1:
					label3.text = '[M] Round Puff Cluster';
					break;
				case 2:
					label3.text = '[M] Cube Model';
					break;
				case 3:
					label3.text = '[M] Sphere Model';
					break;
				case 4:
					label3.text = '[M] Spaceship Model';
					break;
			}
		}

		private function updateScore():void {
			// for now, you earn points over time
			score++;
			// padded with zeroes
			if (score < 10) scoreTf.text = 'Score: 00000' + score;
			else if (score < 100) scoreTf.text = 'Score: 0000' + score;
			else if (score < 1000) scoreTf.text = 'Score: 000' + score;
			else if (score < 10000) scoreTf.text = 'Score: 00' + score;
			else if (score < 100000) scoreTf.text = 'Score: 0' + score;
			else scoreTf.text = 'Score: ' + score;
		}

		private function initGUI():void {
			// a text format descriptor used by all gui labels
			var myFormat:TextFormat = new TextFormat();
			myFormat.color = 0xFFFFFF;
			myFormat.size = 13;
			// create an FPSCounter that displays the framerate on screen
			fpsTf = new TextField();
			fpsTf.x = stage.stageWidth - fpsTf.width;
			fpsTf.y = 0;
			fpsTf.selectable = false;
			fpsTf.autoSize = TextFieldAutoSize.LEFT;
			fpsTf.defaultTextFormat = myFormat;
			fpsTf.text = "Initializing Stage3d...";
			addChild(fpsTf);
			// create a score display
			scoreTf = new TextField();
			scoreTf.x = 560;
			scoreTf.y = 0;
			scoreTf.selectable = false;
			scoreTf.autoSize = TextFieldAutoSize.LEFT;
			scoreTf.defaultTextFormat = myFormat;
			addChild(scoreTf);
			// add some labels to describe each shader
			label1 = new TextField();
			label1.x = 0;
			label1.y = 30;
			label1.selectable = false;
			label1.autoSize = TextFieldAutoSize.LEFT;
			label1.defaultTextFormat = myFormat;
			addChild(label1);
			label2 = new TextField();
			label2.x = 0;
			label2.y = 50;
			label2.selectable = false;
			label2.autoSize = TextFieldAutoSize.LEFT;
			label2.defaultTextFormat = myFormat;
			addChild(label2);
			label3 = new TextField();
			label3.x = 0;
			label3.y = 70;
			label3.selectable = false;
			label3.autoSize = TextFieldAutoSize.LEFT;
			label3.defaultTextFormat = myFormat;
			addChild(label3);

			// force these labels to be set
			nextMesh();
			nextTexture();
			nextBlendmode();
		}

		public function uploadTextureWithMipmaps(dest:Texture, src:BitmapData):void {
			var ws:int = src.width;
			var hs:int = src.height;
			var level:int = 0;
			var tmp:BitmapData;
			var transform:Matrix = new Matrix();
			var tmp2:BitmapData;
			tmp = new BitmapData(src.width, src.height, true, 0x00000000);
			while (ws >= 1 && hs >= 1) {
				tmp.draw(src, transform, null, null, null, true);
				dest.uploadFromBitmapData(tmp, level);
				transform.scale(0.5, 0.5);
				level++;
				ws >>= 1;
				hs >>= 1;
				if (hs && ws) {
					tmp.dispose();
					tmp = new BitmapData(ws, hs, true, 0x00000000);
				}
			}
			tmp.dispose();
		}

		private function onContext3DCreate(event:Event):void {
			// Remove existing frame handler. Note that a context
			// loss can occur at any time which will force you
			// to recreate all objects we create here.
			// A context loss occurs for instance if you hit
			// CTRL-ALT-DELETE on Windows.
			// It takes a while before a new context is available
			// hence removing the enterFrame handler is important!
			if (hasEventListener(Event.ENTER_FRAME)) {
				removeEventListener(Event.ENTER_FRAME, enterFrame);
			}

			// Obtain the current context
			var t:Stage3D = event.target as Stage3D;
			context3D = t.context3D;
			if (context3D == null) {
				// Currently no 3d context is available (error!)
				trace('ERROR: no context3D - video driver problem?');
				return;
			}
			// Disabling error checking will drastically improve performance.
			// If set to true, Flash sends helpful error messages regarding
			// AGAL compilation errors, uninitialized program constants, etc.
			context3D.enableErrorChecking = true;
			// Initialize our mesh data
			initData();
			// The 3d back buffer size is in pixels (2=antialiased)
			context3D.configureBackBuffer(swfWidth, swfHeight, 2, true);
			// assemble all the shaders we need
			initShaders();

			this.leafTexture = context3D.createTexture(leafBmp.width, leafBmp.height, Context3DTextureFormat.BGRA, false);
			uploadTextureWithMipmaps(leafTexture, leafBmp.bitmapData);

			this.fireTexture = context3D.createTexture(fireBmp.width, fireBmp.height, Context3DTextureFormat.BGRA, false);
			uploadTextureWithMipmaps(fireTexture, fireBmp.bitmapData);

			this.lensFlareTexture = context3D.createTexture(lensFlareBmp.width, lensFlareBmp.height, Context3DTextureFormat.BGRA, false);
			uploadTextureWithMipmaps(lensFlareTexture, lensFlareBmp.bitmapData);

			this.glowTexture = context3D.createTexture(glowBmp.width, glowBmp.height, Context3DTextureFormat.BGRA, false);
			uploadTextureWithMipmaps(glowTexture, glowBmp.bitmapData);

			this.smokeTexture = context3D.createTexture(smokeBmp.width, smokeBmp.height, Context3DTextureFormat.BGRA, false);
			uploadTextureWithMipmaps(smokeTexture, smokeBmp.bitmapData);

			terrainTexture = context3D.createTexture(terrainTextureData.width, terrainTextureData.height, Context3DTextureFormat.BGRA, false);
			uploadTextureWithMipmaps(terrainTexture, terrainTextureData.bitmapData);

			// create projection matrix for our 3D scene
			projectionmatrix.identity();
			// 45 degrees FOV, 640/480 aspect ratio, 0.1=near, 100=far
			projectionmatrix.perspectiveFieldOfViewRH(45.0, swfWidth / swfHeight, 0.01, 5000.0);
			// create a matrix that defines the camera location
			viewmatrix.identity();
			// move the camera back a little so we can see the mesh
			viewmatrix.appendTranslation(0, 0, -1.5);
			// tilt the terrain a little so it is coming towards us
			terrainviewmatrix.identity();
			terrainviewmatrix.appendRotation(-60, Vector3D.X_AXIS);
			// start the render loop!
			addEventListener(Event.ENTER_FRAME, enterFrame);
		}

		private function initData():void {
			// parse the OBJ file and create buffers
			trace("Parsing the meshes...");
			this.randomParticlesMesh = new Stage3dObjParser(this.randomParticleClusterData, context3D, 1, true, true);
			this.roundPuffMesh = new Stage3dObjParser(this.roundPuffData, context3D, 1, true, true);
			this.cubeMesh = new Stage3dObjParser(this.cubeObjData, context3D, 1, true, true);
			this.sphereMesh = new Stage3dObjParser(this.sphereObjData, context3D, 1, true, true);
			this.shipMesh = new Stage3dObjParser(this.shipObjData, context3D, 1, true, true);

			// parse the terrain mesh as well
			trace("Parsing the terrain...");
			terrainMesh = new Stage3dObjParser(this.terrainObjData, context3D, 1, true, true);
		}

		private function renderMesh():void {
			if (blendNum > 1) {
				// ignore depth zbuffer
				// always draw polies even those that are behind others
				context3D.setDepthTest(false, Context3DCompareMode.LESS);
			} else {
				// use the depth zbuffer
				context3D.setDepthTest(true, Context3DCompareMode.LESS);
			}
			// clear the transformation matrix to 0,0,0
			modelmatrix.identity();
			context3D.setProgram(shaderProgram1);
			setTexture();
			setBlendmode();
			modelmatrix.appendRotation(t * 0.7, Vector3D.Y_AXIS);
			modelmatrix.appendRotation(t * 0.6, Vector3D.X_AXIS);
			modelmatrix.appendRotation(t * 1.0, Vector3D.Y_AXIS);
			// clear the matrix and append new angles
			modelViewProjection.identity();
			modelViewProjection.append(modelmatrix);
			modelViewProjection.append(viewmatrix);
			modelViewProjection.append(projectionmatrix);
			// pass our matrix data to the shader program
			context3D.setProgramConstantsFromMatrix(Context3DProgramType.VERTEX, 0, modelViewProjection, true);

			switch (meshNum) {
				case 0:
					myMesh = this.randomParticlesMesh;
					break;
				case 1:
					myMesh = this.roundPuffMesh;
					break;
				case 2:
					myMesh = this.cubeMesh;
					break;
				case 3:
					myMesh = this.sphereMesh;
					break;
				case 4:
					myMesh = this.shipMesh;
					break;
			}

			// draw a mesh
			// position
			context3D.setVertexBufferAt(0, myMesh.positionsBuffer, 0, Context3DVertexBufferFormat.FLOAT_3);
			// tex coord
			context3D.setVertexBufferAt(1, myMesh.uvBuffer, 0, Context3DVertexBufferFormat.FLOAT_2);
			// vertex rgba
			context3D.setVertexBufferAt(2, myMesh.colorsBuffer, 0, Context3DVertexBufferFormat.FLOAT_4);
			// render it
			context3D.drawTriangles(myMesh.indexBuffer, 0, myMesh.indexBufferCount);
		}

		private function setTexture():void {
			switch (texNum) {
				case 0:
					context3D.setTextureAt(0, this.leafTexture);
					break;
				case 1:
					context3D.setTextureAt(0, this.fireTexture);
					break;
				case 2:
					context3D.setTextureAt(0, this.lensFlareTexture);
					break;
				case 3:
					context3D.setTextureAt(0, this.glowTexture);
					break;
				case 4:
					context3D.setTextureAt(0, this.smokeTexture);
					break;
			}
		}

		private function renderTerrain():void {
			// texture blending: no blending at all - opaque
			context3D.setBlendFactors(Context3DBlendFactor.ONE, Context3DBlendFactor.ZERO);
			// draw to depth zbuffer and do not draw polies that are obscured
			context3D.setDepthTest(true, Context3DCompareMode.LESS);

			context3D.setTextureAt(0, terrainTexture);
			// simple textured shader
			context3D.setProgram(shaderProgram1);
			// position
			context3D.setVertexBufferAt(0, terrainMesh.positionsBuffer, 0, Context3DVertexBufferFormat.FLOAT_3);
			// tex coord
			context3D.setVertexBufferAt(1, terrainMesh.uvBuffer, 0, Context3DVertexBufferFormat.FLOAT_2);
			// vertex rgba
			context3D.setVertexBufferAt(2, terrainMesh.colorsBuffer, 0, Context3DVertexBufferFormat.FLOAT_4);
			// set up camera angle
			modelmatrix.identity();
			// make the terrain face the right way
			modelmatrix.appendRotation(-90, Vector3D.Y_AXIS);
			// slowly move the terrain around
			modelmatrix.appendTranslation(Math.cos(t / 300) * 1000, Math.cos(t / 200) * 1000 + 500, -130);
			// clear the matrix and append new angles
			modelViewProjection.identity();
			modelViewProjection.append(modelmatrix);
			modelViewProjection.append(terrainviewmatrix);
			modelViewProjection.append(projectionmatrix);
			// pass our matrix data to the shader program
			context3D.setProgramConstantsFromMatrix(Context3DProgramType.VERTEX, 0, modelViewProjection, true);
			context3D.drawTriangles(terrainMesh.indexBuffer, 0, terrainMesh.indexBufferCount);
		}

		//--------------------------------------------------------------------------
		//   							HANDLERS
		//--------------------------------------------------------------------------
		private function enterFrame(e:Event):void {
			// clear scene before rendering is mandatory
			context3D.clear(0, 0, 0);
			// move or rotate more each frame
			t += 2.0;
			// scroll and render the terrain once
			renderTerrain();
			// render whatever mesh is selected
			renderMesh();
			// present/flip back buffer
			// now that all meshes have been drawn
			context3D.present();
			// update the FPS display
			fpsTicks++;
			var now:uint = getTimer();
			var delta:uint = now - fpsLast;
			// only update the display once a second
			if (delta >= 1000) {
				var fps:Number = fpsTicks / delta * 1000;
				fpsTf.text = fps.toFixed(1) + " fps";
				fpsTicks = 0;
				fpsLast = now;
			}
			// update the rest of the GUI
			updateScore();
		}

		private function initShaders():void {
			// A simple vertex shader which does a 3D transformation
			// for simplicity, it is used by all four shaders
			var vertexShaderAssembler:AGALMiniAssembler = new AGALMiniAssembler();
			vertexShaderAssembler.assemble(
					Context3DProgramType.VERTEX,
					// 4x4 matrix multiply to get camera angle
							"m44 op, va0, vc0\n" +
						// tell fragment shader about XYZ
							"mov v0, va0\n" +
						// tell fragment shader about UV
							"mov v1, va1\n" +
						// tell fragment shader about RGBA
							"mov v2, va2"
			);
			// textured using UV coordinates
			var fragmentShaderAssembler1:AGALMiniAssembler
					= new AGALMiniAssembler();
			fragmentShaderAssembler1.assemble
			(
					Context3DProgramType.FRAGMENT,
					// grab the texture color from texture 0
					// and uv coordinates from varying register 1
					// and store the interpolated value in ft0
							"tex ft0, v1, fs0 <2d,linear,repeat,miplinear>\n" +
						// move this value to the output color
							"mov oc, ft0\n"
			);

			// combine shaders into a program which we then upload to the GPU
			shaderProgram1 = context3D.createProgram();
			shaderProgram1.upload(vertexShaderAssembler.agalcode, fragmentShaderAssembler1.agalcode);
		}

		//--------------------------------------------------------------------------
		//  							GETTERS/SETTERS
		//--------------------------------------------------------------------------
	}
}
