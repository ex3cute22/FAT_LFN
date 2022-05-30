//
//  FAT_LFNApp.swift
//  Shared
//
//  Created by Илья Викторов on 25.02.2022.
//

import SwiftUI

@main
struct FAT_LFNApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}

//struct ListFilesView: View {
//    @ObservedObject var fileSystem: FileSystem
//    @State var newSymbol: String = ""
//    @Environment(\.colorScheme) var colorMode
//
//    var body: some View {
//        NavigationView {
//            ZStack {
//                VStack {
//                    Form{
//                        Section("Записи SFN") {
//                            if fileSystem.isRootDir() {
//                                List($fileSystem.entries, id: \.self) { $entry in
//                                    if entry.attr != .volumeLabel {
//                                        ListView(fileSystem: fileSystem, entry: $entry, newSymbol: $newSymbol)
//                                    }
//                                }
//                            }
//                            else {
//                                ForEach(0..<fileSystem.subDir.count, id: \.self) { index in
//                                    if fileSystem.subDir[index].currentEntry.startCluster == fileSystem.currentCluster {
//                                        NavigationLink(destination: InfoFileView(fs: fileSystem, entry: fileSystem.subDir[index].currentEntry)){
//                                            Text(".")
//                                                .bold()
//                                        }
//                                        Text("..")
//                                            .bold()
//                                            .onTapGesture {
//                                                withAnimation {
//                                                    fileSystem.currentCluster = fileSystem.subDir[index].parentEntry.startCluster
//                                                }
//                                            }
//                                        List($fileSystem.subDir[index].entries, id: \.self) { $entry in
//                                            if entry.attr != .volumeLabel {
//                                                ListView(fileSystem: fileSystem, entry: $entry, newSymbol: $newSymbol)
//                                            }
//                                        }
//                                    }
//                                }
//                            }
//                        }
//
//                        Section("Записи LFN") {
//                            if fileSystem.isRootDir() {
//                                List($fileSystem.entriesLFN , id: \.self) { $entry in
//                                    let entrySFN = fileSystem.entries.filter({$0.startCluster == entry.firstCluster}).first!
//                                    NavigationLink(destination: InfoFileView(fs: fileSystem, entry: entry)) {
//                                        HStack {
//                                            Text("\(entry.name_1+entry.name_2+entry.name_3)")
//                                        }
//                                    }
//                                    .listRowBackground(fileSystem.isDeleted(entry: entrySFN) ? Color.red : colorMode == .dark ? Color(.systemGray5) : Color.white)
//                                }
//                            } else {
//                                ForEach(0..<fileSystem.subDir.count, id: \.self) { index in
//                                    if fileSystem.subDir[index].currentEntry.startCluster == fileSystem.currentCluster {
//                                        NavigationLink(destination: InfoFileView(fs: fileSystem, entry: fileSystem.subDir[index].currentEntry)){
//                                            Text(".")
//                                                .bold()
//                                        }
//                                        Text("..")
//                                            .bold()
//                                            .onTapGesture {
//                                                withAnimation {
//                                                    fileSystem.currentCluster = fileSystem.subDir[index].parentEntry.startCluster
//                                                }
//                                            }
//                                        List($fileSystem.subDir[index].entriesLong, id: \.self) { $entry in
//                                            let entrs = fileSystem.isRootDir() ? fileSystem.entries : fileSystem.subDir[fileSystem.getIndexCurDir()!].entries
//                                            let entrySFN = entrs.filter({$0.startCluster == entry.firstCluster}).first!
//                                            NavigationLink(destination: entry.attr == .directory ? nil : InfoFileView(fs: fileSystem, entry: entry)) {
//                                                Text("\(entry.name_1+entry.name_2+entry.name_3)")
//                                            }
//                                            .listRowBackground(fileSystem.isDeleted(entry: entrySFN) ? Color.red : colorMode == .dark ? Color(.systemGray5) : Color.white)
//                                        }
//                                    }
//
//                                }
//                            }
//                        }
//                    }
//                    let entrs = fileSystem.isRootDir() ? fileSystem.entries : fileSystem.subDir[fileSystem.getIndexCurDir()!].entries
//                    let amountOfDeletedFiles = entrs.filter{fileSystem.isDeleted(entry: $0)}.count
//
//                    if amountOfDeletedFiles > 0 {
//                        VStack(spacing: 20) {
//                            TextField("Новый символ", text: $newSymbol)
//                                .onChange(of: newSymbol) { newValue in
//                                    if newValue.count > 1 { //ограничение на 1 символ
//                                        newSymbol = String(newValue.dropLast(newValue.count - 1)).uppercased()
//                                    } else {
//                                        fileSystem.bannedChar.forEach { char in
//                                            if newValue.contains(char) { //проверка на запрещенные символы
//                                                newSymbol = newValue.replacingOccurrences(of: char, with: "")
//                                            }
//                                        }
//
//                                        fileSystem.lfnSpecialChar.forEach { char in
//                                            if newValue.contains(char) {
//                                                newSymbol = newValue.replacingOccurrences(of: char, with: "_")
//                                            }
//                                        }
//
//                                        if newValue.contains(" ") {
//                                            newSymbol = newValue.trimmingCharacters(in: .whitespaces)
//                                        }
//                                    }
//                                }
//                                .padding(14)
//                                .background(
//                                    RoundedRectangle(cornerRadius: 10)
//                                        .stroke(.blue)
//                                )
//                            Button {
//                                withAnimation {
//                                    fileSystem.deleteCompletelyFiles()
//                                }
//                            } label: {
//                                Text("Удалить без восстановления выбранные файлы")
//                            }
//                        }
//                        .padding(14)
//                    }
//
//                }
//                .navigationTitle(fileSystem.getDirectoryName())
//            }
//        }
//    }
//}
//
//struct ListView: View {
//    @State var fileSystem: FileSystem
//    @Binding var entry: Entry
//    @Binding var newSymbol: String
//    @Environment(\.colorScheme) var colorMode
//
//    var body: some View {
//        NavigationLink(destination: InfoFileView(fs: fileSystem, entry: entry)) {
//            HStack {
//                if entry.attr == .directory {
//                    Image(systemName: "folder")
//                }
//                Text(entry.name + "." + entry.ext)
//                    .bold()
//            }
//            .onTapGesture(perform: {
//                if entry.attr == FileAttribute.directory {
//                    withAnimation {
//                        fileSystem.currentCluster = entry.startCluster
//                    }
//                }
//            })
//        }
//        .listRowBackground(fileSystem.isDeleted(entry: entry) ? Color.red : colorMode == .dark ? Color(.systemGray5) : Color.white)
//        .swipeActions(edge: !fileSystem.isDeleted(entry: entry) ? .trailing : .leading) {
//            if !fileSystem.isDeleted(entry: entry) {
//                Button(role: .destructive) {
//                    withAnimation {
//                        if entry.attr == .directory {
//                            if entry.fileSize == fileSystem.clusterSize { //Delete catalog
//                                fileSystem.deleteFiles(entry: entry)
//                                entry.makeFirstByteOfNameDeletedFile()
//                            }
//                        } else {
//                            fileSystem.deleteFiles(entry: entry)
//                            entry.makeFirstByteOfNameDeletedFile()
//                        }
//                    }
//                } label: {
//                    Label("Удалить", systemImage: "trash")
//                }
//            }
//            else {
//                Button {
//                    withAnimation {
//                        if !newSymbol.isEmpty && !fileSystem.duplicateNameCheck(name: String(newSymbol) + String(entry.name.suffix(entry.name.count-1)), ext: entry.ext) {
//                            entry.restoreFirstByteOfName(newSymbol: Character(newSymbol))
//                            fileSystem.recoveryFile(entry: entry)
//                        }
//                    }
//                } label: {
//                    Label("Восстановить", systemImage: "return")
//                }
//                .tint(.blue)
//            }
//        }
//
//    }
//}
