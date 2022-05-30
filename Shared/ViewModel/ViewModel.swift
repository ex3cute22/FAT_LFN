//
//  ViewModel.swift
//  FAT_LFN (iOS)
//
//  Created by Илья Викторов on 21.03.2022.
//

import Foundation
import SwiftUI


class FileSystem: ObservableObject {
    @Published var entries: [Entry] = [] //записи корневого каталога с коротким именем
    @Published var entriesLFN: [EntryLong] = [] //записи корневого каталога с длинным именем
    @Published var fat: [FatBlock] = [] //основная таблица размещения
    @Published var fat2: [FatBlock] = [] //резервная таблица размещения
    @Published var freeSpace: Int //свободное место (в байтах)
    @Published var subDir: [SubDirectory] = [] //пользовательские подкаталоги
    @Published var currentCluster = 0 //{ // кластер текущего каталога
    
    let lfnSpecialChar: [String] = ["+", ",", ".", ";", "=", "[", "]"] //разрешенные символы в длинном названии
    let bannedChar: [String] = ["/", "\\", ":", "*", "?", "<", ">", "\"", "|", "\""] //запрещенные символы в названии
    let firstByteDeletedFile: Character = "�" //метка удаленного файла //"\u{E5}"
    let partitionSize: Int //размер раздела (в байтах)
    let clusterSize: Int //размер кластера (в байтах)
    let numberOfClusters: Int //количество кластеров в разделе
    
    
    init(partitionSize: Int, clusterSize: Int){
        self.partitionSize = partitionSize - (partitionSize % clusterSize)
        self.clusterSize = clusterSize
        self.freeSpace = self.partitionSize
        self.numberOfClusters = (self.partitionSize / self.clusterSize)
        self.fat = Array(repeating: FatBlock(next: BlockAttribute.unused.rawValue, color: .blue), count: numberOfClusters)
        self.entries.append(Entry(name: "", ext: "", attr: .volumeLabel, crtDate: Date(), wrtDate: Date(), startCluster: 0, fileSize: freeSpace))
        self.freeSpace -= clusterSize
        fat[0] = FatBlock(next: BlockAttribute.last.rawValue, color: .gray)
        fat2 = fat
        fat2[3] = FatBlock(next: 12, color: .red)
        fat2[12] = FatBlock(next: -1, color: .red)
    }
    
    //получить процент свободного места на диске
    func getFreeSpacePercentage() -> Int {
        return Int((100*(Double(freeSpace) / Double(partitionSize))).rounded(.up))
    }
    
    //получить цепочку кластеров
    func getSequenceClusters(startCluster: Int) -> [Int] {
        var seq: [Int] = [startCluster]
        
        repeat {
            seq.append(fat[seq.last!].next)
        } while seq.last! != BlockAttribute.last.rawValue
        
        return seq
    }
    
    //проверка на корневой каталог
    func isRootDir() -> Bool {
        return currentCluster == 0
    }
    
    //сделать кластер "битым"
    func makeBadCluster(index: Int) {
        if fat[index].next == BlockAttribute.unused.rawValue && fat2[index].next == BlockAttribute.unused.rawValue {
            fat[index].next = BlockAttribute.bad.rawValue
            fat[index].color = .red
            fat2[index].next = BlockAttribute.bad.rawValue
            fat2[index].color = .red
            freeSpace -= clusterSize
        }
        else if fat[index].next == BlockAttribute.bad.rawValue {
            fat[index].next = BlockAttribute.unused.rawValue
            fat2[index].next = BlockAttribute.unused.rawValue
            freeSpace += clusterSize
        }
    }
    
    //получить индекс выбранного подкаталога
    func getIndexDir(firstCluster: Int) -> Int? {
        return subDir.firstIndex { dir in
            dir.currentEntry.startCluster == firstCluster
        }
    }
    
    //получить индекс текущего подкаталога
    func getIndexCurDir() -> Int? {
        if !isRootDir() {
            return subDir.firstIndex { dir in
                dir.currentEntry.startCluster == currentCluster
            }!
        }
        return nil
    }
    
    //функция проверки диска (сравнение резервной и основной таблицы)
    func checkDisk() -> Int {
        var counter = 0
        for i in 0..<numberOfClusters {
            if fat[i].next != fat2[i].next || fat[i].color != fat2[i].color {
                counter += 1
            }
        }
        self.fat2 = fat
        return counter
    }
    
    //функция получения выделенной памяти под хранения файла
    func roundAllocatedMemory(size: Int) -> Int {
        if size % clusterSize == 0 {
            return size
        }
        return  clusterSize * (size / clusterSize + 1) //example: 6468 (for 4kByte) -> 8192
    }
    
    //функция заполнения fat таблицы
    func fatFilling(table: inout [FatBlock], numberOfClusters: Int, color: Color) -> Int {
        let firstFreeCluster: Int = table.firstIndex(of: table.first(where: { block in
            block.next == BlockAttribute.unused.rawValue
        })!)!
        var pointer = firstFreeCluster
        
        for _ in 0..<numberOfClusters-1 {
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
    
    //функция создания файла
    func createNewFile(fileName: String, ext: String, attr: FileAttribute, fileSize: Int, color: Color) {
        if !isRootDir() {
            if isDeleted(entry: subDir[getIndexCurDir()!].currentEntry) {
                return
            }
        }
        //вычисление количества необходимых кластеров под файл
        var numberOfClusterForFile: Int = Int((Double(fileSize) / Double(clusterSize)).rounded(.up))
        numberOfClusterForFile = attr == FileAttribute.directory ? 1 : numberOfClusterForFile
        print(numberOfClusterForFile)
        
        if numberOfClusterForFile <= fat.map({$0.next == BlockAttribute.unused.rawValue}).count && numberOfClusterForFile <= fat2.map({$0.next == BlockAttribute.unused.rawValue}).count {
            //заполнение основной таблицы
            let firstFreeCluster = fatFilling(table: &fat, numberOfClusters: numberOfClusterForFile, color: color)
            //заполнение резервной таблицы
            fatFilling(table: &fat2, numberOfClusters: numberOfClusterForFile, color: color)
            
            //если lfn
            if fileName.count > 8 {
                let name = make83Alias(longName: fileName)
                let entry = Entry(name: name, ext: ext.uppercased(), attr: attr, crtDate: Date(), wrtDate: Date(), startCluster: firstFreeCluster, fileSize: fileSize)
                
                if entry.attr == .directory {
                    subDir.append(
                        SubDirectory(currentEntry: entry,
                                     parentEntry: isRootDir() ?  entries.first(where: { $0.startCluster == currentCluster})! : subDir[getIndexCurDir()!].currentEntry
                                    )
                    )
                }
                if isRootDir() {
                    entries.append(entry)
                } else {
                    subDir[getIndexCurDir()!].entries.append(entry)
                }
                
                //распределение длинного имени
                let attr = FileAttribute.lfn
                let amountOfEntry = Int((Double(fileName.count + ext.count + 1) / 13).rounded(.up))
                var bufName = Array(String(fileName + "." + ext))
                for _ in 0..<amountOfEntry*13-bufName.count+1 {
                    bufName += " "
                }
                
                for i in 0..<amountOfEntry {
                    let offset = 13*i
                    let entryLong = EntryLong(ord: i+1, name_1: String(bufName[offset..<offset+5]), attr: attr, name_2: String(bufName[offset+5..<offset+11]), firstCluster: firstFreeCluster, name_3: String(bufName[offset+11..<offset+13]))
                    
                    
                    if isRootDir() {
                        entriesLFN.append(entryLong)
                    } else {
                        subDir[getIndexCurDir()!].entriesLong.append(entryLong)
                    }
                }
                updateEntriesInSubdirectories(entry: entry, isAddition: true)
            } else {
                // если sfn
                let entry = Entry(name: fileName.uppercased(), ext: ext.uppercased(), attr: attr, crtDate: Date(), wrtDate: Date(), startCluster: firstFreeCluster, fileSize: fileSize)
                
                if entry.attr == .directory {
                    subDir.append(
                        SubDirectory(currentEntry: entry,
                                     parentEntry: isRootDir() ?  entries.first(where: { $0.startCluster == currentCluster})! : subDir[getIndexCurDir()!].currentEntry
                                    )
                    )
                }
                if isRootDir() {
                    entries.append(entry)
                } else {
                    subDir[getIndexCurDir()!].entries.append(entry)
                }
                updateEntriesInSubdirectories(entry: entry, isAddition: true)
            }
            freeSpace -= attr == .directory ? clusterSize : roundAllocatedMemory(size: fileSize)
        }
    }
    
    //получение имени текущей директории
    func getDirectoryName() -> String {
        if !isRootDir() {
            var currCluster = currentCluster
            var arrNames: [String] = []
            
            repeat {
                let index = getIndexDir(firstCluster: currCluster)
                arrNames.append(subDir[index!].currentEntry.name)
                currCluster = subDir[index!].parentEntry.startCluster
            } while currCluster != 0
            
            return "\\" + arrNames.reversed().joined(separator: "\\")
        }
        return "\\"
    }
    
    //функия проверки файла на дубликат
    func duplicateNameCheck(name: String, ext: String) -> Bool {
        let fullName = name + "." + ext
        let currFullName = name.count > 8 ? fullName : fullName.uppercased()
        
        let entrs = isRootDir() ? entries : subDir[getIndexCurDir()!].entries
        
        for i in entrs.indices {
            let nameToCheck = name.count > 8 ? getLongFileName(entry: entrs[i]) : entrs[i].name + "." + entrs[i].ext
            if currFullName == nameToCheck {
                return true
            }
        }
        return false
    }
    
    //функция получения длинного имени файла
    func getLongFileName(entry: Entry) -> String {
        let startCluster = entry.startCluster
        
        let lfn = isRootDir() ? entriesLFN : subDir[getIndexCurDir()!].entriesLong
        let arrOfEntriesLFN = lfn.filter{$0.firstCluster == startCluster}.sorted{$0.ord < $1.ord}
        
        var fullName = ""
        
        arrOfEntriesLFN.forEach { entry in
            fullName += entry.name_1 + entry.name_2 + entry.name_3
        }
        
        return fullName.trimmingCharacters(in: .whitespaces)
    }
    
    //функция создания псевдонима (формат 8.3)
    func make83Alias(longName: String) -> String {
        var shortName = longName.replacingOccurrences(of: " ", with: "").substring(to: String.Index(encodedOffset: 6)).uppercased()
        for char in lfnSpecialChar {
            shortName = shortName.replacingOccurrences(of: char, with: "_")
        }
        let entrs = isRootDir() ? entries : subDir[getIndexCurDir()!].entries
        var num = entrs.filter{$0.name.contains(shortName)}
        
        //если коротких записей получается больше 4
        while num.count + 1 > 4 {
            shortName = shortName.substring(to: String.Index(encodedOffset: 2))
            for _ in 0..<4 {
                let randomValue = Int.random(in: 0..<16)
                shortName += String(format: "%01X", randomValue)
            }
            num = entrs.filter{$0.name.contains(shortName)}
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
            currCluster = nextCluster
        } while currCluster != BlockAttribute.last.rawValue
        
        currCluster = entry.startCluster
        repeat {
            let nextCluster = fat2[currCluster].next
            fat2[currCluster].color = .blue
            currCluster = nextCluster
        } while currCluster != BlockAttribute.last.rawValue
        
        if entry.attr == .directory {
            let index = getIndexDir(firstCluster: entry.startCluster)!
            subDir[index].currentEntry.name = entry.name
            subDir[index].currentEntry.wrtDate = Date()
        }
    }
    
    //функция удаления файла (частичное)
    func deleteFiles(entry: Entry) {
        var currCluster = entry.startCluster
        
        repeat {
            let nextCluster = fat[currCluster].next
            fat[currCluster].color = .red
            currCluster = nextCluster
        } while currCluster != BlockAttribute.last.rawValue
        
        currCluster = entry.startCluster
        repeat {
            let nextCluster = fat2[currCluster].next
            fat2[currCluster].color = .red
            currCluster = nextCluster
        } while currCluster != BlockAttribute.last.rawValue
        
        if entry.attr == .directory {
            var ent = entry
            ent.makeFirstByteOfNameDeletedFile()
            subDir[getIndexDir(firstCluster: entry.startCluster)!].currentEntry.name = ent.name
        }
    }
    
    //функция полного удаления файлов
    func deleteCompletelyFiles() {
        let entrs = isRootDir() ? entries : subDir[getIndexCurDir()!].entries
        let bufDelEntries = entrs.filter({isDeleted(entry: $0)})
        
        bufDelEntries.forEach { entry in
            var currCluster = entry.startCluster
            repeat {
                let nextCluster = fat[currCluster].next
                fat[currCluster].next = BlockAttribute.unused.rawValue
                fat[currCluster].color = .blue
                currCluster = nextCluster
            } while currCluster != BlockAttribute.last.rawValue
            
            currCluster = entry.startCluster
            repeat {
                let nextCluster = fat2[currCluster].next
                fat2[currCluster].next = BlockAttribute.unused.rawValue
                fat2[currCluster].color = .blue
                currCluster = nextCluster
            } while currCluster != BlockAttribute.last.rawValue
            
            if isRootDir() {
                entries.removeAll{$0 == entry}
                entriesLFN.removeAll { $0.firstCluster == entry.startCluster }
            } else {
                subDir[getIndexCurDir()!].entries.removeAll{$0 == entry}
                subDir[getIndexCurDir()!].entriesLong.removeAll{$0.firstCluster == entry.startCluster}
                updateEntriesInSubdirectories(entry: entry, isAddition: false)
            }
            
            if entry.attr == .directory {
                let index = subDir.firstIndex { dir in
                    dir.currentEntry.startCluster == entry.startCluster
                }!
                subDir.remove(at: index)
            }
            
            freeSpace += entry.attr == .directory ? entry.fileSize : roundAllocatedMemory(size: entry.fileSize)
        }
    }
    
    //обновление записей в директории
    func updateEntriesInSubdirectories(entry: Entry, isAddition: Bool) {
        let operation = isAddition ? 1 : -1
        
        if !isRootDir() {
            var currEntry = subDir[getIndexCurDir()!].currentEntry
            var isDirectory: Bool = false
            
            repeat {
                isDirectory = false
                for i in subDir.indices {
                    if subDir[i].currentEntry.startCluster == currEntry.startCluster {
                        subDir[i].currentEntry.fileSize += entry.fileSize * operation
                        subDir[i].currentEntry.wrtDate = Date()
                    }
                }
                firstLoop: for i in subDir.indices {
                    for j in subDir[i].entries.indices {
                        if subDir[i].entries[j].startCluster == currEntry.startCluster {
                            subDir[i].entries[j].fileSize += entry.fileSize * operation
                            subDir[i].entries[j].wrtDate = Date()
                            currEntry = subDir[i].currentEntry
                            isDirectory = true
                            break firstLoop
                        }
                    }
                }
            } while entries.firstIndex(where: {$0.startCluster == currEntry.startCluster}) == nil
            
            if isDirectory {
                for i in subDir.indices {
                    if subDir[i].currentEntry.startCluster == currEntry.startCluster {
                        subDir[i].currentEntry.fileSize += entry.fileSize * operation
                        subDir[i].currentEntry.wrtDate = Date()
                    }
                }
            }
            
            let index = entries.firstIndex { ent in
                ent.startCluster == currEntry.startCluster
            }!
            entries[index].fileSize += entry.fileSize * operation
            entries[index].wrtDate = Date()
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
}
