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
    var ord: Int //нумерация
    var name_1: String //5 символов имени
    var attr: FileAttribute //атрибут файла
    var name_2: String //6-11 символы
    var firstCluster: Int //номер первого кластера
    var name_3: String //12-13 символы
}

struct Entry: IEntry, Hashable {
    var name: String //название файла
    var ext: String //расширение файла
    var attr: FileAttribute //атрибут файла
    var crtDate: Date //дата создания
    var wrtDate: Date //дата изменения
    var startCluster: Int //номер первого кластера
    var fileSize: Int //размер файла
    
    
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

class SubDirectory: ObservableObject {
    @Published var currentEntry: Entry //.
    @Published var parentEntry: Entry //..
    @Published var entries: [Entry] = []
    @Published var entriesLong: [EntryLong] = []
    
    init(currentEntry: Entry, parentEntry: Entry) {
        self.currentEntry = currentEntry
        self.parentEntry = parentEntry
    }
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
        return String(format: "0x%\(byte*2)X", self)
    }
}
