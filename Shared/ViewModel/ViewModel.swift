//
//  ViewModel.swift
//  FAT_LFN (iOS)
//
//  Created by Илья Викторов on 21.03.2022.
//

import Foundation
import SwiftUI


class FileSystem: ObservableObject {
    @Published var entries: [Entry] = []
    @Published var entriesLFN: [EntryLong] = []
    @Published var fat: [FatBlock] = [] {
        didSet {
//            freeSpace
//            numberOfBadClusters = fat.map{$0.next == BlockAttribute.bad.rawValue}.count
        }
    }
//    {
//        didSet {
//            //freeSpace = partitionSize
//        }
//    }
    @Published var subDir: [SubDirectory] = []
    @Published var fat2: [FatBlock] = [] //резервный
    @Published var freeSpace: Int //свободное место (в байтах)
    @Published var numberOfFiles: Int = 0
    @Published var numberOfBadClusters: Int = 0 //{
//        didSet {
//            freeSpace -= numberOfBadClusters * clusterSize
//        }
//    }
    @Published var currenttCluster = 0 // кластер текущего каталога
    @Published var parentCluster = 0 // кластер родительского каталога
    @Published var currentDir: String = "\\"
    
    let lfnSpecialChar: [String] = ["+", ",", ";", "=", "[", "]"]
    let bannedChar: [String] = ["/", "\\", ":", "*", "?", "<", ">", "\"", "|"]
    let firstByteDeletedFile: Character = "�"//"\u{E5}"
    let partitionSize: Int //размер раздела (в байтах) 65536
    let clusterSize: Int //размер кластера (в байтах) 4 Кб
    let numberOfClusters: Int //количество кластеров в разделе
    
    
    init(partitionSize: Int, clusterSize: Int){
        self.partitionSize = partitionSize - (partitionSize % clusterSize)
        self.clusterSize = clusterSize
        self.freeSpace = self.partitionSize
        self.numberOfClusters = (self.partitionSize / self.clusterSize)
        self.fat = Array(repeating: FatBlock(next: BlockAttribute.unused.rawValue, color: .blue), count: numberOfClusters)
        self.fat2 = fat
        //self.entries.append(Entry(name: "", ext: "", attr: .volumeLabel, modifyTime: Date(), modifyDate: Date(), startCluster: 0, fileSize: 0, isDeleted: false))
        //fat[0] = FatBlock(next: BlockAttribute.last.rawValue, color: .gray)
        fat2[3] = FatBlock(next: 12, color: .red)
        fat2[12] = FatBlock(next: -1, color: .red)
        self.numberOfBadClusters = fat.map{$0.next == BlockAttribute.bad.rawValue}.count
    }
    
    //функция проверки диска (сравнение резервной и основной таблицы)
    func checkDisk() -> Int {
        var counter = 0
        for i in 0..<numberOfClusters {
            if fat[i].next != fat2[i].next {
                counter += 1
            }
        }
        self.fat2 = fat
        return counter
    }
    
//    func openCatalog(catalog: Entry) -> [Entry] {
//        changeCurrentDirectory(catalog: catalog)
//        var entriesFiltered: [Entry] = entries
//        if currentDir != "\\" {
//            entriesFiltered.filter {
//                $0.startCluster == catalog.startCluster
//            }
//        }
//        return entriesFiltered
//    }
    
    //получить цепочку кластеров
    func getSequenceClusters(startCluster: Int) -> [Int] {
        var seq: [Int] = [startCluster+1]
        
        repeat {
            seq.append(fat[seq.last!].next)
        } while seq.last! != BlockAttribute.last.rawValue
    
        return seq
    }

    
//    func getFilesInCurrentCatalog() -> [Entry] {
//        var entriesFiltered: [Entry] = []
//        
//        if currenttCluster == 0 {
//            for i in entries.indices {
//                var isRootDirFile = true
//                for j in entries.indices {
//                    if entries[i] != entries[j] && entries[i].startCluster == entries[j].startCluster {
//                        isRootDirFile = false
//                    }
//                }
//                if isRootDirFile { entriesFiltered.append(entries[i]) }
//            }
//        } else {
//            entriesFiltered = entries.filter { $0.startCluster == currenttCluster }
//        }
//        return entriesFiltered
//    }
    
    //сделать кластер "битым"
    func makeBadCluster(index: Int) {
        if fat[index].next == BlockAttribute.unused.rawValue && fat2[index].next == BlockAttribute.unused.rawValue {
            fat[index].next = BlockAttribute.bad.rawValue
            fat[index].color = .red
            fat2[index].next = BlockAttribute.bad.rawValue
            fat2[index].color = .red
            numberOfBadClusters += 1
            freeSpace -= clusterSize
            
        }
        else if fat[index].next == BlockAttribute.bad.rawValue {
            fat[index].next = BlockAttribute.unused.rawValue
            fat2[index].next = BlockAttribute.unused.rawValue
            freeSpace += clusterSize
        }
    }
    
    //функция создания файла
    func createNewFile(fileName: String, ext: String, attr: FileAttribute, fileSize: Int, color: Color) {
        //вычисление количества необходимых кластеров под файл
        var numberOfClusterForFile: Int = Int((Double(fileSize) / Double(clusterSize)).rounded(.up))
        numberOfClusterForFile = attr == FileAttribute.directory ? 1 : numberOfClusterForFile
        print(numberOfClusterForFile)
        
        func fatFilling(table: inout [FatBlock]) -> Int {
            let firstFreeCluster: Int = table.firstIndex(of: table.first(where: { block in
                block.next == BlockAttribute.unused.rawValue
            })!)!
            var pointer = firstFreeCluster
            
            for _ in 0..<numberOfClusterForFile-1 {
                table[pointer].next = BlockAttribute.last.rawValue
                let firstNextCluster: Int = table.firstIndex(of: table.first(where: { block in
                    block.next == BlockAttribute.unused.rawValue
                })!)!
                table[pointer].next = firstNextCluster
                table[pointer].color = color
                pointer = firstNextCluster
            }
            table[pointer].color = color
            table[pointer].next = BlockAttribute.last.rawValue
            
            return firstFreeCluster
        }
        
        if numberOfClusterForFile <= fat.map({$0.next == BlockAttribute.unused.rawValue}).count && numberOfClusterForFile <= fat2.map({$0.next == BlockAttribute.unused.rawValue}).count {
            //заполнение основной таблицы
            let firstFreeCluster = fatFilling(table: &fat)
            //заполнение резервной таблицы
            fatFilling(table: &fat2)
            
            //если lfn
            if fileName.count > 8 {
                let name = make83Alias(longName: fileName)
                let entry = Entry(name: name, ext: ext.uppercased(), attr: attr, crtDate: Date(), wrtDate: Date(), startCluster: firstFreeCluster, fileSize: fileSize)
                entries.append(entry)
                
                let attr = FileAttribute.lfn
                let amountOfEntry = Int((Double(fileName.count + ext.count + 1) / 13).rounded(.up))
                var bufName = Array(String(fileName + "." + ext))
                for _ in 0..<amountOfEntry*13-bufName.count+1 {
                    bufName += " "
                }
            
                for i in 0..<amountOfEntry {
                    let offset = 13*i
                    let entryLong = EntryLong(ord: i+1, name_1: String(bufName[offset..<offset+5]), attr: attr, name_2: String(bufName[offset+5..<offset+11]), firstCluster: firstFreeCluster, name_3: String(bufName[offset+11..<offset+13]))
                    entriesLFN.append(entryLong)
                }
            } else {
                let entry = Entry(name: fileName.uppercased(), ext: ext.uppercased(), attr: attr, crtDate: Date(), wrtDate: Date(), startCluster: firstFreeCluster, fileSize: fileSize)
                entries.append(entry)
            }
            
            freeSpace -= fileSize
        }
    }
    
    func changeCurrentDirectory(catalog: Entry) {
        currentDir += catalog.name + "\\"
    }
    
    //функия проверки файла на дубликат
    func duplicateNameCheck(name: String, ext: String) -> Bool {
        let currFullName = name + "." + ext
        
        for i in entries.indices {
            let nameToCheck = name.count > 8 ? getLongFileName(entry: entries[i]) : entries[i].name
            if currFullName == nameToCheck {
                return true
            }
        }
        return false
    }
    
    //функция получения длинного имени файла
    func getLongFileName(entry: Entry) -> String {
        let startCluster = entry.startCluster
        let arrOfEntriesLFN = entriesLFN.filter{$0.firstCluster == startCluster}.sorted{$0.ord < $1.ord}
        
        var fullName = ""
        
        arrOfEntriesLFN.forEach { entry in
            fullName += entry.name_1 + entry.name_2 + entry.name_3
        }
       //let indexOfStartExt = fullName.lastIndex(of: ".")!
    
        return fullName.trimmingCharacters(in: .whitespaces)//String(fullName[String.Index(encodedOffset: 0)..<indexOfStartExt])
    }
    
    //функция создания псевдонима (формат 8.3)
    func make83Alias(longName: String) -> String {
        var shortName = longName.replacingOccurrences(of: " ", with: "")
            .substring(to: String.Index(encodedOffset: 6)).uppercased()
        var num = entries.filter{$0.name.contains(shortName)}
        
        //если коротких записей получается больше 4
        while num.count + 1 > 4 {
            shortName = shortName.substring(to: String.Index(encodedOffset: 2))
            for _ in 0..<4 {
                let randomValue = Int.random(in: 0..<16)
                shortName += String(format: "%01X", randomValue)
            }
            num = entries.filter{$0.name.contains(shortName)}
        }
        
        shortName += "~\(num.count+1)"
        return shortName
    }
    
    //функция проверки на удаленный файл
    func isDeleted(entry: Entry) -> Bool {
        return String(entry.name.prefix(1)) == String(firstByteDeletedFile)
    }

    //функция восстановления файла
    func recoveryFile(entry: Entry) {
        var currCluster = entry.startCluster
        
        repeat {
            let nextCluster = fat[currCluster].next
            fat[currCluster].color = .blue
            //fat[currCluster].next = BlockAttribute.unused.rawValue
            currCluster = nextCluster
        } while currCluster != BlockAttribute.last.rawValue
    }
    
    //функция удаления файла (частичное)
    func deleteFiles(entry: Entry) {
        var currCluster = entry.startCluster
        
        repeat {
            let nextCluster = fat[currCluster].next
            fat[currCluster].color = .red
            //fat[currCluster].next = BlockAttribute.unused.rawValue
            currCluster = nextCluster
        } while currCluster != BlockAttribute.last.rawValue
    }
    
    //функция полного удаления файлов
    func deleteCompletelyFiles() {
        let bufDelEntries = entries.filter({isDeleted(entry: $0)})
        bufDelEntries.forEach { entry in
            entries.removeAll{$0 == entry}
            entriesLFN.removeAll { $0.firstCluster == entry.startCluster }
        }
    }
    
    //функция получения строки ASCII значений имени файла
    func getNumberASCII(str: String) -> String {
        var temp: String = ""
        str.forEach { char in
            let optionalASCIIvalue = char.unicodeScalars.filter{$0.isASCII}.first?.value
            if let ASCIIValue = optionalASCIIvalue {
                temp += String(format: "%2X ", ASCIIValue)
            }
        }
        return temp
    }

    
    
//    //var linksToNextCluster: [Int] //массив ссылок на следующие кластеры
//    var busyCluster: [Int]
//    var bitMap: [Int]
//    //var clusterState: [Int] //массив состояний кластеров  (0x00 - свободный кластер, 0xf7 - дефектный кластер, 0xff - конец файла)
//
//    var fileName: [String] //массив имен файлов
//    var fileClass: [String] //массив типа файлов (файл/каталог)
//    var fileSize: [Int] //массив размеров файлов
//    var dateCreated: [String] //массив дат создания файлов
//    var dateModified: [String] //массив дат изменения файлов
//
//
//    var counter: UInt8 = 0 //счетчик
//    var toDelete: UInt8 //номер удаляемого файла
//    var isDeleted: [UInt8] //массив состояния удаления (удален файл или нет)
//
}


