////
////  SplashSettingsView.swift
////  FAT_LFN (iOS)
////
////  Created by Илья Викторов on 18.05.2022.
////
//
//import SwiftUI
//
//struct SplashSettingsView: View {
//    let maxAmountOfClusters = 65_536
//    let maxClusterSize = 32 * 1024
//    @State var clusterSize = 4096
//    @State var indexVolumeCluster = 3
//    @State var partitionSize = 256 * 1024 * 1024
//    let clusterSizes: [Int] = [512, 1024, 2*1024, 4*1024, 8*1024, 16*1024, 32*1024]
//    
//    var body: some View {
//        VStack {
//            Text("Размер кластера: ")
//            Slider(value: $indexVolumeCluster, in: 0..<Double(clusterSizes.count))
//                .padding(.horizontal)
//            
//            // 16_777_216:268_435_456
//            //HStack {TextField(, text:, prompt: w) }
//
//            Text("Размер раздела: ")
//            Slider(value: $partitionSize, in: 0..<Double(clusterSizes.count))
//                .padding(.horizontal)
//            Text(partitionSize)
//            
//            Button {
//                
//            } label: {
//                Text("Создать")
//            }
//
//
//            // 4096:65536
//        }
//    }
//}
////
////struct SplashSettingsView_Previews: PreviewProvider {
////    static var previews: some View {
////        SplashSettingsView()
////    }
////}
