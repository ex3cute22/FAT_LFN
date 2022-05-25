//
//  ListFilesView.swift
//  FAT_LFN (iOS)
//
//  Created by Илья Викторов on 18.04.2022.
//

import SwiftUI

struct ListFilesView: View {
    @ObservedObject var fileSystem: FileSystem
    @State var isShowingAlert = false
    @State var newSymbol: String = ""
    
    var body: some View {
        NavigationView {
            VStack {
                Form{
                    Section("Записи SFN") {
                        if fileSystem.currentDir != "\\" {
                            HStack {
                                Text(".")
                            }
                            HStack {
                                Text("..")
                            }
                        }
                        List($fileSystem.entries, id: \.self) { $entry in
                            // if entry.startCluster == fileSystem.currenttCluster {
                            NavigationLink(destination: entry.attr == .directory ? nil : InfoFileView(fs: fileSystem, entry: entry)) {
                                HStack {
                                    if entry.attr == .directory {
                                        Image(systemName: "folder")
                                    }
                                    let name = entry.name//.first ? fileSystem.makeFirstByteDeletedFile(name: entry.name) : entry.name
                                    Text("\(name + "." + entry.ext)")
                                        .bold()
                                    //Text("\tНачальный кластер: \(entry.startCluster+1)")
                                }
                                //                                .onTapGesture(perform: {
                                //                                    if entry.attr == FileAttribute.directory {
                                //                                        fileSystem.changeCurrentDirectory(catalog: entry)
                                //                                    } else if !entry.isDeleted {
                                //                                        print(entry.name.toAsciiHex())
                                //                                        print(fileSystem.getSequenceClusters(startCluster: entry.startCluster))
                                //                                        print(fileSystem.getFullNameFile(entry: entry))
                                //                                    }
                                //                                })
                                
                            }
                            .listRowBackground(fileSystem.isDeleted(entry: entry) ? Color.red : Color.white)
                            .swipeActions(edge: !fileSystem.isDeleted(entry: entry) ? .trailing : .leading) {
                                if !fileSystem.isDeleted(entry: entry) {
                                    Button(role: .destructive) {
                                        withAnimation {
                                            if entry.attr == .directory {
                                                //Delete catalog
                                            } else {
                                                fileSystem.deleteFiles(entry: entry)
                                                entry.makeFirstByteOfNameDeletedFile()
                                            }
                                        }
                                    } label: {
                                        Label("Удалить", systemImage: "trash")
                                    }
                                }
                                else {
                                    Button {
                                        withAnimation {
                                            fileSystem.recoveryFile(entry: entry)
                                            isShowingAlert.toggle()
                                            //alertView()
                                            //entry.restoreFirstByteOfName(newSymbol: Character(newSymbol))
                                        }
                                    } label: {
                                        Label("Восстановить", systemImage: "return")
                                    }
                                    .tint(.blue)
                                }
                            }
                        }
                    }
                    Section("Записи LFN") {
                        List($fileSystem.entriesLFN , id: \.self) { $entry in
                            NavigationLink(destination: entry.attr == .directory ? nil : InfoFileView(fs: fileSystem, entry: entry)) {
                                HStack {
                                    Text("\(entry.name_1+entry.name_2+entry.name_3)")
                                }
                            }
                            //                            let entrySFN = fileSystem.entries.filter({$0.startCluster == entry.firstCluster}).first!
                            //                            .listRowBackground(fileSystem.isDeleted(entry: entrySFN)  ? Color.red : Color.white)
                        }
                    }
                }
                Button {
                    withAnimation {
                        fileSystem.deleteCompletelyFiles()
                    }
                } label: {
                    Text("Удалить без восстановления выбранные файлы")
                }
            }
            .navigationTitle(fileSystem.currentDir)
        }
        .textFieldAlert(isShowing: $isShowingAlert, text: $newSymbol, title: "Добавить новый символ")
    }
    
    //    func alertView() {
    //        let alert = UIAlertController(title: "Новый первый символ", message: "Найдено \(fileSystem.checkDisk()) отличий.", preferredStyle: .alert)
    //
    //        alert.addTextField { newSymbol in
    //            newSymbol.placeholder = "Укажите символ"
    //        }
    //
    //        alert.addAction(UIAlertAction(title: "Ок", style: .default, handler: { _ in
    //            withAnimation {
    //
    //            }
    //        }))
    ////        alert.addAction(UIAlertAction(title: "Отмена", style: .cancel, handler: { _ in
    ////
    ////        }))
    //
    //        UIApplication.shared.windows.first?.rootViewController?.present(alert, animated: true, completion: nil)
    //    }
}


struct TextFieldAlert<Presenting>: View where Presenting: View {

    @Binding var isShowing: Bool
    @Binding var text: String
    let presenting: Presenting
    let title: String

    var body: some View {
        GeometryReader { (deviceSize: GeometryProxy) in
            ZStack {
                self.presenting
                    .disabled(isShowing)
                VStack {
                    Text(self.title)
                    TextField("", text: self.$text)
                    Divider()
                    HStack {
                        Button(action: {
                            withAnimation {
                                self.isShowing.toggle()
                            }
                        }) {
                            Text("Dismiss")
                        }
                    }
                }
                .padding()
                .background(Color.white)
                .frame(
                    width: deviceSize.size.width*0.7,
                    height: deviceSize.size.height*0.7
                )
                .shadow(radius: 1)
                .opacity(self.isShowing ? 1 : 0)
            }
        }
    }

}

extension View {

    func textFieldAlert(isShowing: Binding<Bool>,
                        text: Binding<String>,
                        title: String) -> some View {
        TextFieldAlert(isShowing: isShowing,
                       text: text,
                       presenting: self,
                       title: title)
    }

}
