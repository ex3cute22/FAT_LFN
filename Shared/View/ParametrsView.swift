//
//  ParametrsView.swift
//  FAT_LFN (iOS)
//
//  Created by Илья Викторов on 22.03.2022.
//

import SwiftUI

struct ParametrsView: View {
    @State var partitionSize = ""
    @State var clusterSize = ""
    let MIN_FAT16 = 4096
    var body: some View {
        VStack {
            Text("Укажите параметры")
                .frame(alignment: .center)
            
            HStack {
                TextField("Размер раздела: ", text: $partitionSize)
                //Slider(value: $fileSize, in: 1...Double(), step: 1)
                    //  .padding(.horizontal)
                Text("Кб")
            }
            HStack {
                TextField("Размер кластера: ", text: $clusterSize)
                Text("Кб")
            }
            Button {
                
            } label: {
                HStack {
                    Spacer()
                    Text("Принять")
                        .foregroundColor(.white)
                        .padding()
                        .font(.system(size: 14, weight: .bold))
                    Spacer()
                }
                .background(Color.purple)
                .cornerRadius(20)
            }
        }
        .keyboardType(.numberPad)
    }
}

struct ParametrsView_Previews: PreviewProvider {
    static var previews: some View {
        ParametrsView()
    }
}
