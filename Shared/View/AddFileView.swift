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
    @State var banToCreate = true
    @State var nameIsEmpty = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 25) {
                Toggle("Каталог", isOn: $isDirectory)
                TextField("Название файла", text: $name)
                    .textFieldStyle(name: name, condition: isDuplicate || nameIsEmpty)
                    .autocapitalization(.none)
                    .onChange(of: name) { newValue in
                        if newValue.count > 255 { //ограничение на 255 символов
                            name = String(newValue.dropLast(newValue.count - 255))
                        }
                        
                        fileSystem.bannedChar.forEach { char in
                            if newValue.contains(char) { //проверка на запрещенные символы
                                name = newValue.replacingOccurrences(of: char, with: "")
                            }
                        }
                        
                        withAnimation {
                            isDuplicate = fileSystem.duplicateNameCheck(name: name, ext: ext)
                            nameIsEmpty = name.isEmpty
                            banToCreate = nameIsEmpty || ext.isEmpty || isDuplicate || ext.count != 3
                            fileSystem.lfnSpecialChar.forEach { char in
                                if name.contains(char) && name.count <= 8 {
                                    banToCreate = true
                                }
                            }
                        }
                    }
                if isDuplicate && !nameIsEmpty {
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
                        fileSystem.bannedChar.forEach { char in
                            if newValue.contains(char) { //проверка на запрещенные символы
                                ext = newValue.replacingOccurrences(of: char, with: "")
                            }
                        }
                        
                        fileSystem.lfnSpecialChar.forEach { char in
                            if newValue.contains(char) { //проверка на спец символы
                                ext = newValue.replacingOccurrences(of: char, with: "_")
                            }
                        }
                        
                        if newValue.count > 3 {
                            ext = String(newValue.dropLast(newValue.count - 3))
                        }
                        
                        withAnimation {
                            isDuplicate = fileSystem.duplicateNameCheck(name: name, ext: ext)
                            banToCreate = nameIsEmpty || ext.isEmpty || isDuplicate || ext.count != 3
                            fileSystem.lfnSpecialChar.forEach { char in
                                if name.contains(char) && name.count <= 8 {
                                    banToCreate = true
                                }
                            }
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
                }
                ColorPicker("Выбор цвета кластеров", selection: $color, supportsOpacity: false)
                Spacer()
                Button {
                    name = name.trimmingCharacters(in: .whitespaces)
                    ext = ext.trimmingCharacters(in: .whitespaces)
                    
                    if !banToCreate {
                        fileSystem.createNewFile(fileName: name, ext: ext, attr: isDirectory ? .directory : .sfn, fileSize: isDirectory ? fileSystem.clusterSize : Int(fileSize), color: color)
                        presentationMode.wrappedValue.dismiss()
                    }
                } label: {
                    Text("Создать")
                        .bold()
                }
                .opacity(banToCreate ? 0 : 1)
                .disabled(banToCreate)
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
