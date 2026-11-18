package com.gemmea.app

import android.content.Context
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import io.flutter.FlutterInjector
import org.tensorflow.lite.DataType
import org.tensorflow.lite.Interpreter
import java.io.File
import java.io.FileInputStream
import java.nio.ByteBuffer
import java.nio.ByteOrder
import java.nio.MappedByteBuffer
import java.nio.channels.FileChannel

/**
 * Native INT8 TFLite vision runner for SautiLM-Nuru-Agri (224x224x3 uint8 -> 9-class probabilities).
 * Returns null cleanly when `assets/models/sautilm-nuru-agri.tflite` has not yet been installed.
 */
class NuruVisionInterpreter(private val context: Context) {
    companion object {
        private const val ASSET_KEY = "assets/models/sautilm-nuru-agri.tflite"
        private const val SHARED_MODEL_PATH = "/storage/emulated/0/Download/Gemma/sautilm-nuru-agri.tflite"
        private const val INPUT_SIZE = 224
        private const val NUM_CLASSES = 9
    }

    private var interpreter: Interpreter? = null

    private fun loadModelBuffer(): ByteBuffer? {
        val sharedFile = File(SHARED_MODEL_PATH)
        if (sharedFile.exists() && sharedFile.length() > 1024) {
            FileInputStream(sharedFile).use { fis ->
                val channel = fis.channel
                return channel.map(FileChannel.MapMode.READ_ONLY, 0, sharedFile.length())
            }
        }
        return try {
            val lookupKey = FlutterInjector.instance().flutterLoader().getLookupKeyForAsset(ASSET_KEY)
            val afd = context.assets.openFd(lookupKey)
            FileInputStream(afd.fileDescriptor).use { fis ->
                val channel = fis.channel
                val mapped: MappedByteBuffer = channel.map(
                    FileChannel.MapMode.READ_ONLY,
                    afd.startOffset,
                    afd.declaredLength
                )
                mapped
            }
        } catch (_: Exception) {
            null
        }
    }

    fun classify(imageBytes: ByteArray): List<Double>? {
        val interp = interpreter ?: run {
            val buf = loadModelBuffer() ?: return null
            Interpreter(buf, Interpreter.Options().setNumThreads(2)).also { interpreter = it }
        }

        val bitmap = BitmapFactory.decodeByteArray(imageBytes, 0, imageBytes.size) ?: return null
        val scaled = Bitmap.createScaledBitmap(bitmap, INPUT_SIZE, INPUT_SIZE, true)
        val pixels = IntArray(INPUT_SIZE * INPUT_SIZE)
        scaled.getPixels(pixels, 0, INPUT_SIZE, 0, 0, INPUT_SIZE, INPUT_SIZE)

        val inType = interp.getInputTensor(0).dataType()
        val outType = interp.getOutputTensor(0).dataType()

        val inputBuffer: ByteBuffer = if (inType == DataType.FLOAT32) {
            ByteBuffer.allocateDirect(INPUT_SIZE * INPUT_SIZE * 3 * 4).order(ByteOrder.nativeOrder()).apply {
                for (px in pixels) {
                    putFloat(((px shr 16) and 0xFF).toFloat())
                    putFloat(((px shr 8) and 0xFF).toFloat())
                    putFloat((px and 0xFF).toFloat())
                }
                rewind()
            }
        } else {
            ByteBuffer.allocateDirect(INPUT_SIZE * INPUT_SIZE * 3).order(ByteOrder.nativeOrder()).apply {
                for (px in pixels) {
                    put(((px shr 16) and 0xFF).toByte())
                    put(((px shr 8) and 0xFF).toByte())
                    put((px and 0xFF).toByte())
                }
                rewind()
            }
        }

        return if (outType == DataType.FLOAT32) {
            val output = Array(1) { FloatArray(NUM_CLASSES) }
            interp.run(inputBuffer, output)
            output[0].map { f -> f.toDouble().coerceIn(0.0, 1.0) }
        } else {
            val output = Array(1) { ByteArray(NUM_CLASSES) }
            interp.run(inputBuffer, output)
            output[0].map { b -> (b.toInt() and 0xFF) / 255.0 }
        }
    }
}
