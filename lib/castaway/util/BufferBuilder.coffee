#
# Copyright (C) 2013-2014, Infthink (Beijing) Technology Co., Ltd.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS-IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
#    limitations under the License.
#

class BufferBuilder

    constructor: (@initialCapacity = 512) ->
        @buffers = [new Buffer(@initialCapacity)]
        @writeIndex = 0
        @length = 0

    appendUInt8: (x) ->
        @appendInternal(Buffer.prototype.writeUInt8, 1, x)

    appendUInt16LE: (x) ->
        @appendInternal(Buffer.prototype.writeUInt16LE, 2, x)

    appendUInt16BE: (x) ->
        @appendInternal(Buffer.prototype.writeUInt16BE, 2, x)

    appendUInt32LE: (x) ->
        @appendInternal(Buffer.prototype.writeUInt32LE, 4, x)

    appendUInt32BE: (x) ->
        @appendInternal(Buffer.prototype.writeUInt32BE, 4, x)

    appendInt8: (x) ->
        @appendInternal(Buffer.prototype.writeInt8, 1, x)

    appendInt16LE: (x) ->
        @appendInternal(Buffer.prototype.writeInt16LE, 2, x)

    appendInt16BE: (x) ->
        @appendInternal(Buffer.prototype.writeInt16BE, 2, x)

    appendInt32LE: (x) ->
        @appendInternal(Buffer.prototype.writeInt32LE, 4, x)

    appendInt32BE: (x) ->
        @appendInternal(Buffer.prototype.writeInt32BE, 4, x)

    appendFloatLE: (x) ->
        @appendInternal(Buffer.prototype.writeFloatLE, 4, x)

    appendFloatBE: (x) ->
        @appendInternal(Buffer.prototype.writeFloatBE, 4, x)

    appendDoubleLE: (x) ->
        @appendInternal(Buffer.prototype.writeDoubleLE, 8, x)

    appendDoubleBE: (x) ->
        @appendInternal(Buffer.prototype.writeDoubleBE, 8, x)

    # Append a (subsequence of a) Buffer
    appendBuffer: (source) ->
        if source.length == 0 then return this

        tail = @buffers[@buffers.length - 1]
        spaceInCurrent = tail.length - @writeIndex

        if source.length <= spaceInCurrent
            # We can fit the whole thing in the current buffer
            source.copy tail, @writeIndex
            @writeIndex += source.length
        else
            # Copy as much as we can into the current buffer
            if spaceInCurrent # Buffer.copy does not handle the degenerate case well
                source.copy tail, @writeIndex # , start, start + spaceInCurrent);

            # Fit the rest into a new buffer. Make sure it is at least as big as
            # what we're being asked to add, and also follow our double-previous-buffer pattern.
            newBuf = new Buffer Math.max tail.length * 2, source.length

            @buffers.push newBuf
            @writeIndex = source.copy newBuf, 0, spaceInCurrent

        @length += source.length

        return this

    appendInternal: (encoder, size, x) ->
        buf = @buffers[@buffers.length - 1]
        if @writeIndex + size <= buf.length
            encoder.call buf, x, @writeIndex, true
            @writeIndex += size
            @length += size
        else
            scratchBuffer = new Buffer size
            encoder.call scratchBuffer, x, 0, true
            @appendBuffer scratchBuffer
        return this

    appendString: (str, encoding) ->
        return @appendBuffer(new Buffer(str, encoding))

    # Convert to a plain Buffer
    toBuffer: ->
        concatted = new Buffer(@length)
        @copy(concatted)
        return concatted

    # Copy into targetBuffer
    copy: (targetBuffer, targetStart, sourceStart, sourceEnd) ->
        targetStart or (targetStart = 0)
        sourceStart or (sourceStart = 0)
        sourceEnd != undefined || (sourceEnd = @length)

        # Validation.Besides making us fail nicely, this makes it so we can skip checks below.
        if (targetStart < 0 || (targetStart > 0 && targetStart >= targetBuffer.length))
            throw new Error("targetStart is out of bounds")

        if (sourceEnd < sourceStart)
            throw new Error("sourceEnd < sourceStart")

        if (sourceStart < 0 || (sourceStart > 0 && sourceStart >= this.length))
            throw new Error("sourceStart is out of bounds");

        if (sourceEnd > this.length)
            throw new Error("sourceEnd out of bounds")

        sourceEnd = Math.min(sourceEnd, sourceStart + (targetBuffer.length - targetStart))
        targetWriteIdx = targetStart
        readBuffer = 0

        # Skip through our buffers until we get to where the copying should start.
        copyLength = sourceEnd - sourceStart
        skipped = 0

        while (skipped < sourceStart)
            buffer = @buffers[readBuffer]
            if (buffer.length + skipped < targetStart)
                skipped += buffer.length
            else
                # Do the first copy.This one is different from the others in that it
                # does not start from the beginning of one of our internal buffers.
                copyStart = sourceStart - skipped
                inThisBuffer = Math.min(copyLength, buffer.length - copyStart)
                buffer.copy(targetBuffer, targetWriteIdx, copyStart, copyStart + inThisBuffer)
                targetWriteIdx += inThisBuffer
                copyLength -= inThisBuffer
                readBuffer++
                break
            readBuffer++

        # Copy the rest.Note that we can't run off of our end because we validated the range up above
        while (copyLength > 0)
            buffer = @buffers[readBuffer]
            toCopy = Math.min(buffer.length, copyLength)
            buffer.copy(targetBuffer, targetWriteIdx, 0, toCopy)
            copyLength -= toCopy
            targetWriteIdx += toCopy
            readBuffer++

        # Return how many bytes were copied
        return sourceEnd - sourceStart

module.exports.BufferBuilder = BufferBuilder