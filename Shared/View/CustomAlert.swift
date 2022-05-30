//
//  CustomAlert.swift
//  FAT_LFN (iOS)
//
//  Created by Илья Викторов on 26.05.2022.
//

import SwiftUI

struct CustomAlert: View {
    @Environment(\.presentationMode) var presentationMode
    @Binding var text: String
    var body: some View {
        VStack {
            TextField("", text: $text)
            Button {
                presentationMode.wrappedValue.dismiss()
            } label: {
                Text("Добавить")
            }
        }
    }
}
