//
//  SignalProcessing.swift
//  MetalCircle
//
//  Created by Nhan Tran on 4/3/23.
//

import Accelerate


class SignalProcessing {
    static func RootMeanSquare(data: UnsafeMutablePointer<Float>, frameLength: UInt) -> Float {
        var val: Float = 0
        vDSP_measqv(data, 1, &val, frameLength)
        
        var decibel = 10 * log10f(val)
        
        // invert decibel to +ve range where 0(silent) -> 160 (loudest)
        // Shift the dB value so that 0 dB corresponds to silence and 160 dB corresponds to the loudest possible sound.
        decibel = 160 + decibel

        // Only take into account the dB range from 120 to 160, so the full scale range (FSR) is 40 dB.
        decibel = decibel - 120
        
        // Calculate the divisor needed to convert the dB value to a normalized value between 0.3 and 0.6.
        let divisor = Float(40/0.3)
        
        
        // Calculate the adjusted value by dividing the dB value by the divisor and adding 0.3.
        var adjustedVal = 0.3 + decibel/divisor
        
        //cutoff
        if (adjustedVal < 0.3) {
            adjustedVal = 0.3
        } else if (adjustedVal > 0.6) {
            adjustedVal = 0.6
        }
        return adjustedVal
    }
    
    /**
     Linear interpolation between the current and previous values to generate 11 intermediate values to smooth out the data between the two points.
     */
    static func linearInterpolate(current: Float, previous: Float) -> [Float]{
        var vals = [Float](repeating: 0, count: 11)
        vals[10] = current
        vals[5] = (current + previous)/2
        vals[2] = (vals[5] + previous)/2
        vals[1] = (vals[2] + previous)/2
        vals[8] = (vals[5] + current)/2
        vals[9] = (vals[10] + current)/2
        vals[7] = (vals[5] + vals[9])/2
        vals[6] = (vals[5] + vals[7])/2
        vals[3] = (vals[1] + vals[5])/2
        vals[4] = (vals[3] + vals[5])/2
        vals[0] = (previous + vals[1])/2

        return vals
    }
    
    static func fft(data: UnsafeMutablePointer<Float>, setup: OpaquePointer) -> [Float] {
        // Declaring an array of floating point numbers with a size of 1024 and initializing all elements with the value of 0.
        var realIn = [Float](repeating: 0, count: 1024)
        var imagIn = [Float](repeating: 0, count: 1024)
        var realOut = [Float](repeating: 0, count: 1024)
        var imagOut = [Float](repeating: 0, count: 1024)
        
        //fill in real input part with audio samples
        for i in 0...1023 {
            realIn[i] = data[i]
        }
    
        /*
         Execute Discrete Fourier Transform (DFT) on the input signal
            setup is a precomputed DFT setup object, created using vDSP_DFT_CreateSetup.
            realIn and imagIn are arrays of Float values that represent the real and imaginary components of the input signal to the DFT.
            realOut and imagOut are arrays of Float values that will contain the real and imaginary components of the output of the DFT.
         */
        vDSP_DFT_Execute(setup, &realIn, &imagIn, &realOut, &imagOut)
        //our results are now inside realOut and imagOut

        /**
         DSPSplitComplex structure is a type used in the Accelerate framework to represent a complex number as a split real and imaginary component.
            struct DSPSplitComplex {
                var realp: UnsafeMutablePointer<Float>
                var imagp: UnsafeMutablePointer<Float>
            }
         */
        var complex = DSPSplitComplex(realp: &realOut, imagp: &imagOut)
        
        //setup magnitude output
        var magnitudes = [Float](repeating: 0, count: 512)
        
        //calculate magnitude results
        vDSP_zvabs(&complex, 1, &magnitudes, 1, 512)
        
        //normalize
        var normalizedMagnitudes = [Float](repeating: 0.0, count: 512)
        var scalingFactor = Float(25.0/512)
        vDSP_vsmul(&magnitudes, 1, &scalingFactor, &normalizedMagnitudes, 1, 512)
        
        return normalizedMagnitudes
    }
}
