package {
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.display.Sprite;
	import flash.display.Stage3D;
	import flash.display.StageAlign;
	import flash.display.StageScaleMode;
	import flash.display3D.Context3D;
	import flash.display3D.Context3DProgramType;
	import flash.display3D.Context3DTextureFormat;
	import flash.display3D.Context3DVertexBufferFormat;
	import flash.display3D.IndexBuffer3D;
	import flash.display3D.Program3D;
	import flash.display3D.VertexBuffer3D;
	import flash.display3D.textures.Texture;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.geom.Matrix;
	import flash.geom.Matrix3D;
	import flash.geom.Vector3D;
	import flash.text.TextField;
	import flash.text.TextFieldAutoSize;
	import flash.text.TextFormat;
	import flash.utils.getTimer;

	[SWF(frameRate=60, width=960, height=740)]
	public class Main extends Sprite {

		[Embed(source="../assets/texture.jpg")]
		private var myTextureBitmap:Class;

		private var myTextureData:Bitmap = new myTextureBitmap();
		// The Molehill Texture that uses the above myTextureData
		private var myTexture:Texture;

		[Embed(source="../assets/my_texture.jpg")]
		private var myTextureBitmap2:Class;

		private var myTextureData2:Bitmap = new myTextureBitmap2();
		// The Molehill Texture that uses the above myTextureData
		private var myTexture2:Texture;

		// constants used during inits
		private const swfWidth:int = 960;
		private const swfHeight:int = 640;
		private const textureSize:int = 512;
		// the 3d graphics window on the stage
		private var context3D:Context3D;
		// the compiled shader used to render our mesh
		private var shaderProgram:Program3D;
		// the uploaded vertexes used by our mesh
		private var vertexBuffer:VertexBuffer3D;
		// the uploaded indexes of each vertex of the mesh
		private var indexBuffer:IndexBuffer3D;
		// the data that defines our 3d mesh model
		private var meshVertexData:Vector.<Number>;// the indexes that define what data is used by each vertex
		private var meshIndexData:Vector.<uint>;
		// matrices that affect the mesh location and camera angles
		private var projectionMatrix:PerspectiveMatrix3D = new PerspectiveMatrix3D();
		private var modelMatrix:Matrix3D = new Matrix3D();
		private var viewMatrix:Matrix3D = new Matrix3D();
		private var modelViewProjection:Matrix3D = new Matrix3D();
		// a simple frame counter used for animation
		private var t:Number = 0;
		private var fpsTf:TextField;
		private var shaderProgram1:Program3D;
		private var shaderProgram2:Program3D;
		private var shaderProgram3:Program3D;
		private var shaderProgram4:Program3D;
		private var fpsTicks:int;
		private var fpsLast:uint;

		public function Main() {
			if (stage != null) {
				init();
			} else {
				this.addEventListener(Event.ADDED_TO_STAGE, onAddedToStage);
			}
		}

		//--------------------------------------------------------------------------
		//   							PUBLIC METHODS
		//--------------------------------------------------------------------------
		private function init():void {
			this.stage.scaleMode = StageScaleMode.NO_SCALE;
			this.stage.align = StageAlign.TOP_LEFT;

			this.stage.stage3Ds[0].addEventListener(Event.CONTEXT3D_CREATE, onContext3DCreate);
			this.stage.stage3Ds[0].requestContext3D();

			initGUI();
		}

		//--------------------------------------------------------------------------
		//   					  PRIVATE\PROTECTED METHODS
		//--------------------------------------------------------------------------
		private function initData():void {
			// Defines which vertex is used for each polygon
			// In this example a square is made from two triangles
			meshIndexData = new <uint>[
				0, 1, 2,
				0, 2, 3
			];

			// Raw data used for each of the 4 vertexes
			// Position XYZ, texture coord UV, normal XYZ, vertex RGBA
			meshVertexData = Vector.<Number>([
				//X, Y, Z, U, V, nX, nY, nZ, R, G, B, A
				-1, -1, 1, 0, 0, 0, 0, 1, 1.0, 0.0, 0.0, 1.0,
				1, -1, 1, 1, 0, 0, 0, 1, 0.0, 1.0, 0.0, 1.0,
				1, 1, 1, 1, 1, 0, 0, 1, 0.0, 0.0, 1.0, 1.0,
				-1, 1, 1, 0, 1, 0, 0, 1, 1.0, 1.0, 1.0, 1.0
			]);
		}

		private function initGUI():void {
			// a text format descriptor used by all gui labels
			var myFormat:TextFormat = new TextFormat();
			myFormat.color = 0xFFFFFF;
			myFormat.size = 13;
			// create an FPSCounter that displays the framerate on screen
			fpsTf = new TextField();
			fpsTf.x = 0;
			fpsTf.y = 0;
			fpsTf.selectable = false;
			fpsTf.autoSize = TextFieldAutoSize.LEFT;
			fpsTf.defaultTextFormat = myFormat;
			fpsTf.text = "Initializing Stage3d...";
			addChild(fpsTf);
			// add some labels to describe each shader
			var label1:TextField = new TextField();
			label1.x = 100;
			label1.y = 180;
			label1.selectable = false;
			label1.autoSize = TextFieldAutoSize.LEFT;
			label1.defaultTextFormat = myFormat;
			label1.text = "Shader 1: Textured";
			addChild(label1);
			var label2:TextField = new TextField();
			label2.x = 400;
			label2.y = 180;
			label2.selectable = false;

			label2.autoSize = TextFieldAutoSize.LEFT;
			label2.defaultTextFormat = myFormat;
			label2.text = "Shader 2: Vertex RGB";
			addChild(label2);
			var label3:TextField = new TextField();
			label3.x = 80;
			label3.y = 440;
			label3.selectable = false;
			label3.autoSize = TextFieldAutoSize.LEFT;
			label3.defaultTextFormat = myFormat;
			label3.text = "Shader 3: Vertex RGB + Textured";
			addChild(label3);
			var label4:TextField = new TextField();
			label4.x = 340;
			label4.y = 440;
			label4.selectable = false;
			label4.autoSize = TextFieldAutoSize.LEFT;
			label4.defaultTextFormat = myFormat;
			label4.text = "Shader 4: Textured + setProgramConstants";
			addChild(label4);
		}

		//--------------------------------------------------------------------------
		//   							HANDLERS
		//--------------------------------------------------------------------------
		private function onAddedToStage(event:Event):void {
			this.removeEventListener(Event.ADDED_TO_STAGE, onAddedToStage);
		}

		private function onContext3DCreate(event:Event):void {
			/*Remove existing frame handler. Note that a context
			 loss can occur at any time which will force you
			 to recreate all objects we create here.
			 A context loss occurs for instance if you hit
			 CTRL-ALT-DELETE on Windows.
			 It takes a while before a new context is available
			 hence removing the enterFrame handler is important!*/
			removeEventListener(Event.ENTER_FRAME, enterFrame);

			// Obtain the current context
			var t:Stage3D = event.target as Stage3D;
			context3D = t.context3D;
			if (context3D == null) {
				// Currently no 3d context is available (error!)
				return;
			}

			// Disabling error checking will drastically improve performance.
			// If set to true, Flash will send helpful error messages regarding
			// AGAL compilation errors, uninitialized program constants, etc.
			context3D.enableErrorChecking = true;

			// Initialize our mesh data
			initData();

			// The 3d back buffer size is in pixels
			context3D.configureBackBuffer(swfWidth, swfHeight, 0, true);

			// assemble all the shaders we need
			initShaders();

			// upload the mesh indexes
			indexBuffer = context3D.createIndexBuffer(meshIndexData.length);
			indexBuffer.uploadFromVector(meshIndexData, 0, meshIndexData.length);
			// upload the mesh vertex data
			// since our particular data is
			// x, y, z, u, v, nx, ny, nz
			// each vertex uses 8 array elements
			vertexBuffer = context3D.createVertexBuffer(meshVertexData.length / 12, 12);
			vertexBuffer.uploadFromVector(meshVertexData, 0, meshVertexData.length / 12);

			this.myTexture = context3D.createTexture(textureSize, textureSize, Context3DTextureFormat.BGRA, false);
			generateMipmap(this.myTexture, this.myTextureData);

			this.myTexture2 = context3D.createTexture(textureSize, textureSize, Context3DTextureFormat.BGRA, false);
			generateMipmap(this.myTexture2, this.myTextureData2);
			// create projection matrix for our 3D scene
			projectionMatrix.identity();
			// 45 degrees FOV, 640/480 aspect ratio, 0.1=near, 100=far
			projectionMatrix.perspectiveFieldOfViewRH(45.0, swfWidth / swfHeight, 0.01, 100.0);
			// create a matrix that defines the camera location
			viewMatrix.identity();
			// move the camera back a little so we can see the mesh
			viewMatrix.appendTranslation(0, 0, -7);

			// start animating
			this.addEventListener(Event.ENTER_FRAME, enterFrame);
			this.stage.addEventListener(MouseEvent.MOUSE_WHEEL, onMouseWheel);
		}

		private function generateMipmap(texture:Texture, textureData:Bitmap):void {
			// Generate mipmaps
			var ws:int = textureData.bitmapData.width;
			var hs:int = textureData.bitmapData.height;
			var level:int = 0;
			var tmp:BitmapData;
			var transform:Matrix = new Matrix();
			tmp = new BitmapData(ws, hs, true, 0x00000000);
			while (ws >= 1 && hs >= 1) {
				tmp.draw(textureData.bitmapData, transform, null, null, null, true);
				texture.uploadFromBitmapData(tmp, level);
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

		private function initShaders():void {

			// A simple vertex shader which does a 3D transformation
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
							"mov v2, va2\n"
			);

			// textured using UV coordinates
			var fragmentShaderAssembler1:AGALMiniAssembler = new AGALMiniAssembler();
			fragmentShaderAssembler1.assemble(
					Context3DProgramType.FRAGMENT,
					// grab the texture color from texture 0
					// and uv coordinates from varying register 1
					// and store the interpolated value in ft0
							"tex ft0, v1, fs0 <2d,repeat,miplinear>\n" +
						// move this value to the output color
							"mov oc, ft0\n"
			);

			// no texture, RGBA from the vertex buffer data
			var fragmentShaderAssembler2:AGALMiniAssembler = new AGALMiniAssembler();
			fragmentShaderAssembler2.assemble(
					Context3DProgramType.FRAGMENT,
					// grab the color from the v2 register
					// which was set in the vertex program
					"mov oc, v2\n"
			);

			// textured using UV coordinates AND colored by vertex RGB
			var fragmentShaderAssembler3:AGALMiniAssembler = new AGALMiniAssembler();
			fragmentShaderAssembler3.assemble(
					Context3DProgramType.FRAGMENT,
					// grab the texture color from texture 0
					// and uv coordinates from varying register 0
							"tex ft0, v1, fs0 <2d,repeat,miplinear>\n" +
						// and uv coordinates from varying register 1
							"tex ft1, v1, fs1 <2d,repeat,miplinear>\n" +
						// multiply by the value stored in v2 (the vertex rgb)
							"mul ft2, v2, ft0\n" +
							"add ft3, ft0, ft1\n" +
						// move this value to the output color
							"mov oc, ft3\n"
			);

			// textured using UV coordinates and
			// tinted using a fragment constant
			var fragmentShaderAssembler4:AGALMiniAssembler = new AGALMiniAssembler();
			fragmentShaderAssembler4.assemble(
					Context3DProgramType.FRAGMENT,
					// grab the texture color from texture 0
					// and uv coordinates from varying register 1
							"tex ft0, v1, fs0 <2d,repeat,miplinear>\n" +
						// multiply by the value stored in fc0
							"mul ft1, fc0, ft0\n" +
						// move this value to the output color
							"mov oc, ft1\n"
			);

			// combine shaders into a program which we then upload to the GPU
			shaderProgram1 = context3D.createProgram();
			shaderProgram1.upload(vertexShaderAssembler.agalcode, fragmentShaderAssembler1.agalcode);
			shaderProgram2 = context3D.createProgram();
			shaderProgram2.upload(vertexShaderAssembler.agalcode, fragmentShaderAssembler2.agalcode);
			shaderProgram3 = context3D.createProgram();
			shaderProgram3.upload(vertexShaderAssembler.agalcode, fragmentShaderAssembler3.agalcode);
			shaderProgram4 = context3D.createProgram();
			shaderProgram4.upload(vertexShaderAssembler.agalcode, fragmentShaderAssembler4.agalcode);
		}

		private function onMouseWheel(event:MouseEvent):void {
			if (event.delta > 0) {
				this.viewMatrix.appendTranslation(0, 0, -1);
			} else {
				this.viewMatrix.prependTranslation(0, 0, 1);
			}
		}

		private function enterFrame(event:Event):void {
			// clear scene before rendering is mandatory
			context3D.clear(0, 0, 0);
			context3D.setProgram(shaderProgram);

			t += 2.0;

			for (var looptemp:int = 0; looptemp < 4; looptemp++) {
				// clear the transformation matrix to 0,0,0
				modelMatrix.identity();
				// each mesh has a different texture,
				// shader, position and spin speed
				switch (looptemp) {
					case 0:
						context3D.setTextureAt(0, myTexture);
						context3D.setProgram(shaderProgram1);
						modelMatrix.appendRotation(t * 0.7, Vector3D.Y_AXIS);
						modelMatrix.appendRotation(t * 0.6, Vector3D.X_AXIS);
						modelMatrix.appendRotation(t * 1.0, Vector3D.Y_AXIS);
						modelMatrix.appendTranslation(-3, 3, 0);
						break;
					case 1:
						context3D.setTextureAt(0, null);
						context3D.setProgram(shaderProgram2);
						modelMatrix.appendRotation(t * -0.2, Vector3D.Y_AXIS);
						modelMatrix.appendRotation(t * 0.4, Vector3D.X_AXIS);
						modelMatrix.appendRotation(t * 0.7, Vector3D.Y_AXIS);
						modelMatrix.appendTranslation(3, 3, 0);
						break;
					case 2:
						context3D.setProgramConstantsFromVector(Context3DProgramType.FRAGMENT, 0, Vector.<Number>([ 1, Math.abs(Math.cos(t / 50)), 0, 1 ]));
						context3D.setTextureAt(0, myTexture);
						context3D.setTextureAt(1, myTexture2);
						context3D.setProgram(shaderProgram3);
						modelMatrix.appendRotation(t * 1.0, Vector3D.Y_AXIS);
						modelMatrix.appendRotation(t * -0.2, Vector3D.X_AXIS);
						modelMatrix.appendRotation(t * 0.3, Vector3D.Y_AXIS);
						modelMatrix.appendTranslation(-3, -3, 0);
						break;
					case 3:
						context3D.setProgramConstantsFromVector(Context3DProgramType.FRAGMENT, 0, Vector.<Number>([ 1, Math.abs(Math.cos(t / 50)), 0, 1 ]));
						context3D.setTextureAt(0, myTexture);
						context3D.setProgram(shaderProgram4);
						modelMatrix.appendRotation(t * 0.3, Vector3D.Y_AXIS);
						modelMatrix.appendRotation(t * 0.3, Vector3D.X_AXIS);
						modelMatrix.appendRotation(t * -0.3, Vector3D.Y_AXIS);
						modelMatrix.appendTranslation(3, -3, 0);
						break;
				}

				// clear the matrix and append new angles
				modelViewProjection.identity();
				modelViewProjection.append(modelMatrix);
				modelViewProjection.append(viewMatrix);
				modelViewProjection.append(projectionMatrix);
				// pass our matrix data to the shader program
				context3D.setProgramConstantsFromMatrix(Context3DProgramType.VERTEX, 0, modelViewProjection, true);

				// associate the vertex data with current shader program
				// position
				context3D.setVertexBufferAt(0, vertexBuffer, 0, Context3DVertexBufferFormat.FLOAT_3);
				// tex coord
				context3D.setVertexBufferAt(1, vertexBuffer, 3, Context3DVertexBufferFormat.FLOAT_2);
				// vertex rgba
				context3D.setVertexBufferAt(2, vertexBuffer, 8, Context3DVertexBufferFormat.FLOAT_4);
				// finally draw the triangles
				context3D.drawTriangles(indexBuffer, 0, meshIndexData.length / 3);

				context3D.setTextureAt(0, null);
				context3D.setTextureAt(1, null);
			}


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
		}

		//--------------------------------------------------------------------------
		//  							GETTERS/SETTERS
		//--------------------------------------------------------------------------
	}
}
