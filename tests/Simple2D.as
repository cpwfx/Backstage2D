package  
{
	import com.adobe.utils.AGALMiniAssembler;
	import com.adobe.utils.PerspectiveMatrix3D;
	import flash.display.BitmapData;
	import flash.display.Sprite;
	import flash.display.Stage3D;
	import flash.display3D.Context3D;
	import flash.display3D.Context3DProgramType;
	import flash.display3D.Context3DVertexBufferFormat;
	import flash.display3D.IndexBuffer3D;
	import flash.display3D.Program3D;
	import flash.display3D.textures.Texture;
	import flash.display3D.Context3DTextureFormat;
	import flash.display3D.Context3DBlendFactor;
	import flash.display3D.VertexBuffer3D;
	import flash.events.Event;
	import flash.geom.Matrix3D;
	import flash.geom.Rectangle;
	
	
	import flash.display3D.Context3DRenderMode;
	import flash.display.StageScaleMode;
	import flash.display.StageAlign;
	
	/**
	 * A Simple2D example for playing around with AGAL and whatnot.
	 * @author Kevin Newman
	 */
	public class Simple2D extends Sprite 
	{
		[Embed(source="../assets/molepeople.jpg")]
		private static const PirateImage : Class;
		private static const pirateBMD:BitmapData = new PirateImage().bitmapData;
		
		private var stage3D:Stage3D;
		private var context3D:Context3D;
		
		private var indexBuffer:IndexBuffer3D;
		private var vbData:Vector.<Number>;
		private var vertexBuffer:VertexBuffer3D;
		private var uvBuffer:VertexBuffer3D;
		private var texture:Texture;
		private var program:Program3D;
		private var viewMatrix:Matrix3D;
		private var simpleSprite:Rectangle;
		
		public function Simple2D() 
		{
			stage.scaleMode = StageScaleMode.NO_SCALE;
			stage.align = StageAlign.TOP_LEFT;
			
			stage3D = stage.stage3Ds[0];
			stage3D.addEventListener(Event.CONTEXT3D_CREATE, onContextCreate);
			stage3D.requestContext3D();
		}
		
		private function onContextCreate(event:Event):void 
		{
			context3D = stage3D.context3D;
			context3D.enableErrorChecking = true;
			context3D.configureBackBuffer( stage.stageWidth, stage.stageHeight, 2, false);
			
			var assembler:AGALMiniAssembler = new AGALMiniAssembler;
			program = context3D.createProgram();
			
			context3D.setProgram( program );
			program.upload(
				assembler.assemble( Context3DProgramType.VERTEX,
					"dp4 op.x, va0, vc0 \n"+ // transform from stream 0 to output clipspace
					"dp4 op.y, va0, vc1 \n"+
					//"dp4 op.z, va0, vc2 \n"+
					"mov op.z, vc2.z \n"+
					"mov op.w, vc3.w \n"+
					"mov v0, va1.xy \n"+ // copy texcoord from stream 1 to fragment program
					"mov v0.z, va0.z \n" // copy alpha from stream 0 to fragment program
				),
				assembler.assemble( Context3DProgramType.FRAGMENT,
					"tex ft0, v0, fs0 <2d,clamp,linear,nomip> \n"+
					"mul ft0, ft0, v0.zzzz\n" +
					"mov oc, ft0 \n"
				)
			);
			
			texture = context3D.createTexture(
				pirateBMD.width, pirateBMD.height, Context3DTextureFormat.BGRA, false
			);
			texture.uploadFromBitmapData( pirateBMD );
			
			simpleSprite = new Rectangle( 0, 0, pirateBMD.width, pirateBMD.height );
			
			indexBuffer = context3D.createIndexBuffer( 6 );
			vertexBuffer = context3D.createVertexBuffer( 4, 3 );
			uvBuffer = context3D.createVertexBuffer( 4, 2 );
			
			indexBuffer.uploadFromVector(new <uint>[0, 1, 2, 1, 2, 3], 0, 6);
			vbData = new <Number>[
			/* lt */	simpleSprite.left,	simpleSprite.top,		1, // x, y, alpha
			/* rt */	simpleSprite.right,	simpleSprite.top,		1,
			/* lb */	simpleSprite.left,	simpleSprite.bottom,	1,
			/* rb */	simpleSprite.right,	simpleSprite.bottom,	1
			];
			vertexBuffer.uploadFromVector( vbData, 0, 4 );
			
			uvBuffer.uploadFromVector( new <Number>[
			/* lt */	0, 0, // x, y
			/* rt */	1, 0,
			/* lb */	0, 1,
			/* rb */	1, 1
				], 0, 4
			);
			
			// Set vertex buffer, this is what we access in vertex shader register va0
			context3D.setVertexBufferAt(0, vertexBuffer, 0, Context3DVertexBufferFormat.FLOAT_3);
			context3D.setVertexBufferAt(1, uvBuffer, 0, Context3DVertexBufferFormat.FLOAT_2);
			
			viewMatrix = new Matrix3D();
			viewMatrix.appendTranslation(-stage.stageWidth>>1, -stage.stageHeight>>1, 0);            
			viewMatrix.appendScale(2.0 / stage.stageWidth, -2.0 / stage.stageHeight, 1);
			
			context3D.setBlendFactors(Context3DBlendFactor.ONE, Context3DBlendFactor.ONE_MINUS_SOURCE_ALPHA);
			
			// Set the projection matrix as a vertex program constant, this is what we access in vertex shader register vc0
			context3D.setProgramConstantsFromMatrix(
				Context3DProgramType.VERTEX, 0, viewMatrix, true
			);
			
			context3D.setTextureAt(0, texture );
			
			addEventListener( Event.ENTER_FRAME, onRenderFrame );
		}
		
		private function onRenderFrame(event:Event):void 
		{
			if (!context3D) return;
			context3D.clear(0, 0, 0, 0);
			//context3D.setProgram( program );
			//context3D.setBlendFactors(Context3DBlendFactor.ONE, Context3DBlendFactor.ONE_MINUS_SOURCE_ALPHA);
			//context3D.setProgramConstantsFromMatrix( Context3DProgramType.VERTEX, 0, viewMatrix, true );
			//context3D.setTextureAt(0, texture );
			//context3D.setVertexBufferAt(0, vertexBuffer, 0, Context3DVertexBufferFormat.FLOAT_3);
			//context3D.setVertexBufferAt(1, uvBuffer, 0, Context3DVertexBufferFormat.FLOAT_2);
			context3D.drawTriangles(indexBuffer, 0, 2);
			context3D.present();
		}
		
	}
}
