//
//  AddFileView.swift
//  FAT_LFN (iOS)
//
//  Created by Илья Викторов on 22.03.2022.
//

import SwiftUI

struct AddFileView: View {
    @Environment(\.presentationMode) var presentationMode
    @ObservedObject var fileSystem: FileSystem
    @State var name: String = ""
    @State var ext: String = ""
    @State var attr: String = ""
    @State var fileSize: Double = 4096
    @State var color: Color = .blue
    @State var isDirectory = false
    @State var isDuplicate = false
    @State var currChar = ""
    
    var body: some View {
        NavigationView {
            VStack(spacing: 25) {
                Toggle("Каталог", isOn: $isDirectory)
                TextField("Название файла", text: $name)
                    .textFieldStyle(name: name, condition: isDuplicate)
                    .autocapitalization(.none)
                    .onChange(of: name) { newValue in
                        if newValue.count > 255 {
                            name = String(newValue.dropLast(newValue.count - 255))
                        }
                        
                        fileSystem.bannedChar.forEach { char in
                            if newValue.contains(char) {
                                name = newValue.replacingOccurrences(of: char, with: "")
                                print("symbol: \(char), name: \(name))")
                            }
                        }
                        
                        if newValue.count < 8 {
                            fileSystem.lfnSpecialChar.forEach { char in
                                if newValue.contains(char) {
                                    name = newValue.replacingOccurrences(of: char, with: "")
                                    //print("symbol: \(char), name: \(name))")
                                }
                            }
                        }
                        withAnimation {
                            isDuplicate = fileSystem.duplicateNameCheck(name: name, ext: ext)
                        }
                    }
                if isDuplicate {
                    withAnimation {
                        Text("Файл с таким именем уже есть!")
                    }
                } else if name.count > 8 {
                    withAnimation {
                        Text("\(fileSystem.make83Alias(longName: name))")
                    }
                }
                TextField("Название расширения", text: $ext)
                    .textFieldStyle(name: ext, condition: ext.count != 3)
                    .autocapitalization(.none)
                    .onChange(of: ext) { newValue in
                        if newValue.count > 3 {
                            ext = String(newValue.dropLast(newValue.count - 3))
                        }
                        withAnimation {
                            isDuplicate = fileSystem.duplicateNameCheck(name: name, ext: ext)
                        }
                    }
                if !isDirectory {
                    VStack {
                        if fileSystem.freeSpace > 1 {
                            Slider(value: $fileSize, in: 1...Double(fileSystem.freeSpace), step: 1)
                                .padding(.horizontal)
                        }
                        Text("Размер файла (в байтах): \(Int(fileSize))")
                    }
                    ColorPicker("Выбор цвета кластеров", selection: $color, supportsOpacity: false)
                }
                Spacer()
                Button {
                    if !fileSystem.duplicateNameCheck(name: name, ext: ext) {
                        fileSystem.createNewFile(fileName: name, ext: ext, attr: isDirectory ? .directory : .sfn, fileSize: isDirectory ? fileSystem.clusterSize : Int(fileSize), color: color)
                        presentationMode.wrappedValue.dismiss()
                    }
                } label: {
                    Text("Создать")
                        .bold()
                }
                .opacity(name.isEmpty || ext.isEmpty || isDuplicate || ext.count != 3 ? 0 : 1)
                .disabled(name.isEmpty || ext.isEmpty || isDuplicate || ext.count != 3)
                .animation(.interactiveSpring())
            }
            .padding()
            .navigationTitle("Создание записи")
        }
        .animation(.spring(), value: name)
    }
}

extension TextField {
    func textFieldStyle(name: String, condition: Bool = false) -> some View {
        modifier(Modifier(name: name, condition: condition))
    }
}

struct Modifier: ViewModifier {
    var name: String
    var condition: Bool
    func body(content: Content) -> some View {
        content
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(name == "" ? Color.blue : condition ? Color.red : Color.green, lineWidth: name == "" ?  1 : 2)
            )
    }
}


//                TextField("Атрибут файла", text: $attr)
//                    .textFieldStyle(name: attr)
//                    .keyboardType(.decimalPad)
//                    .onChange(of: attr) { newValue in
//                        attr.removeAll { $0 != "0" && $0 != "1"}
//                        if newValue.count > 4 {
//                        attr = String(newValue.dropLast(newValue.count - 4))
//                        }
//                    }
