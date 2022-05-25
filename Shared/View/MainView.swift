//
//  MainView.swift
//  FAT_LFN (iOS)
//
//  Created by Илья Викторов on 25.02.2022.
//

import SwiftUI

struct MainView: View {
    @State var isShowFile = false
    @State var isCreateFile = false
    @State var showInfo = false
    @State var showAlert = false
    @ObservedObject var fileSystem = FileSystem(partitionSize: 16 * 65_536, clusterSize: 4096) //FileSystem(partitionSize: 256 * 1024 * 1024, clusterSize: 4 * 1024)
        //FileSystem(partitionSize: 16 * 65_536, clusterSize: 4096)
    @State var indexCurrFAT = 0
    
    var body: some View {
        NavigationView {
            VStack {
                Picker("FAT:", selection: $indexCurrFAT) {
                    Text("Основная").tag(0)
                    Text("Резервная").tag(1)
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)
                MapOfClustersView(fs: fileSystem, currFat: indexCurrFAT == 0 ? $fileSystem.fat : $fileSystem.fat2)
                HStack {
                    Text("Подробности")
                    Spacer()
                    Button {
                        withAnimation(.spring()) {
                            self.showInfo.toggle()
                        }
                    } label: {
                        Image(systemName: showInfo ? "chevron.down" : "chevron.right")
                    }
                }
                .padding()
                
                if showInfo {
                    VStack(alignment: .leading) {
                        Text("Свободное пространство: \(fileSystem.freeSpace)")
                        Text("Размер кластера: \(fileSystem.clusterSize)")
                    }
                }
            }
            .navigationBarItems(
                leading:
                Button {
                    withAnimation(.spring()) {
                        self.isShowFile.toggle()
                    }
                } label: {
                    Image(systemName: "book")
                },
                trailing:
                    Button {
                        withAnimation(.spring()) {
                            if indexCurrFAT == 0 && fileSystem.freeSpace != 0 {
                                self.isCreateFile.toggle()
                            } else {
                                alertView()
                            }
                        }
                    } label: {
                        Image(systemName: indexCurrFAT == 0 ? "plus" : "opticaldisc")
                            .foregroundColor(fileSystem.freeSpace == 0 && indexCurrFAT == 0 ? .gray : .blue)
                    })
            
            .navigationTitle("Карта кластеров")
        }
        .sheet(isPresented: $isShowFile) {
            ListFilesView(fileSystem: fileSystem)
        }
        .sheet(isPresented: $isCreateFile) {
            AddFileView(fileSystem: fileSystem)
        }
    }
        func alertView() {
            let alert = UIAlertController(title: "Проверка диска", message: "Найдено \(fileSystem.checkDisk()) отличий.", preferredStyle: .alert)

            alert.addAction(UIAlertAction(title: "Ок", style: .default, handler: { _ in
                withAnimation {

                }
            }))
            
            UIApplication.shared.windows.first?.rootViewController?.present(alert, animated: true, completion: nil)
        }
}

//struct MainView_Previews: PreviewProvider {
//    static var previews: some View {
//        MainView(fileSystem: FileSystem(partitionSize: 1048576, clusterSize: 4096))
//    }
//}

struct MapOfClustersView: View {
    @ObservedObject var fs: FileSystem
    @Binding var currFat: [FatBlock]
    
    
    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack {
                let columns = 8
                let rows = currFat.count / columns
                VStack(alignment: .center) {
                    ForEach(0..<rows) { i in
                        HStack(alignment: .center) {
                            Text("\(i*columns + 1)")
                                .frame(width: 50, height: 30, alignment: .center)
                            ForEach(0..<columns) { j in
                                let index = i*columns + j
                                ZStack {
                                    Rectangle()
                                        .foregroundColor(currFat[index].next == BlockAttribute.unused.rawValue ? .gray : currFat[index].next == BlockAttribute.bad.rawValue ? .red : currFat[index].color)
                                    if currFat[index].next == BlockAttribute.bad.rawValue {
                                        Text("BC")
                                            .bold()
                                    } else if currFat[index].next == BlockAttribute.last.rawValue {
                                        Text("F")
                                            .bold()
                                    } else if currFat[index].next != BlockAttribute.unused.rawValue {
                                        Text("\(currFat[index].next+1)")
                                            .bold()
                                    }
                                }
                                .onTapGesture(perform: {
                                    fs.makeBadCluster(index: index)
                                })
                                .frame(width: 30, height: 30)
                                .foregroundColor(.white)
                            }
                        }
                    }
                }
            }
        }
        .padding([.top, .trailing])
    }
}

