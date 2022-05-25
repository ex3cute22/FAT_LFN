//
//  FileSystem.swift
//  FAT_LFN (iOS)
//
//  Created by Илья Викторов on 25.02.2022.
//

/*
 FAT16
 
 
 */

import Foundation
import SwiftUI


struct BootSector {
    
}

protocol IEntry {}

struct EntryLong: IEntry, Hashable {
    var ord: Int //for numeration
    var name_1: String //5 symbols
    var attr: FileAttribute //
    //var type: Character //
    var name_2: String //6-11 symbols
    var firstCluster: Int
    var name_3: String //12-13 symbols
}


struct Entry: IEntry, Hashable {
    var name: String
    var ext: String
    var attr: FileAttribute
    var crtDate: Date
    var wrtDate: Date
    var startCluster: Int
    var fileSize: Int
    
    func getFileName() -> String {
        return name + ext
    }
    
    mutating func makeFirstByteOfNameDeletedFile() { //"\u{E5}"
        name = "�" + name.substring(from: String.Index(encodedOffset: 1))
    }
    
    mutating func restoreFirstByteOfName(newSymbol: Character) {
        name = String(newSymbol) + name.substring(from: String.Index(encodedOffset: 3))
    }
}

enum FileAttribute: Int {
    case volumeLabel = 0x08
    case lfn = 0x0f
    case sfn = 0x20
    case directory = 0x10
}

struct FatBlock: Equatable {
    var next: Int
    var color: Color
}


enum BlockAttribute: Int {
    case unused = 0x0
    case bad = 0xfff7
    case last = 0xffff
}


struct RootDirectory {
    var entries: [Entry] = []
    var entriesLFN: [EntryLong] = []
}


struct SubDirectory {
    var currentEntry: Entry //.
    var parentEntry: Entry //..
    var entries: [Entry]
    var entryLong: [EntryLong]
}


public extension String {
    func toAsciiHex() -> String {
        var temp: String = ""
        self.forEach { char in
            let optionalASCIIvalue = char.unicodeScalars.filter{$0.isASCII}.first?.value
            if let ASCIIValue = optionalASCIIvalue {
                temp += String(format: "%2X ", ASCIIValue)
            } else {
                temp += "E5 "
            }
        }
        return temp
    }
}

public extension Int {
    func toHex(byte: UInt = 1) -> String {
        return String(format: "%\(byte*2)X", self)
    }
}
