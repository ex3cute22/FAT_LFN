//
//  InfoFileView.swift
//  FAT_LFN (iOS)
//
//  Created by Илья Викторов on 21.05.2022.
//

import SwiftUI

struct InfoFileView: View {
    @State var fs: FileSystem
    @State var entry: IEntry
    @State var asciiMode = false
    
    var body: some View {
        NavigationView {
            if let entry = entry as? Entry {
                VStack(alignment: .leading) {
                    let name = entry.getFileName()
                    Text("**DIR_Name:** \(asciiMode ? name.toAsciiHex() : name)")
                    Text("**DIR_Attr:** \(entry.attr.rawValue.toHex())")
                    Text("**DIR_CrtTime:** \(entry.crtDate.formatted(date: .abbreviated, time: .shortened))")
                    Text("**DIR_WrtTime:** \(entry.wrtDate.formatted(date: .abbreviated, time: .shortened))")
                    Text("**DIR_FstClusHI:** 0")
                    Text("**DIR_FstClusLO:** \(asciiMode ? (entry.startCluster + 1).toHex() : String(entry.startCluster + 1))")
                    Text("**DIR_FileSize:** \(asciiMode ? String(format: "0x%5X ", entry.fileSize) : String(entry.fileSize))")
                    Spacer(minLength: 50)
                    if entry.attr != .directory {
                        Text("**Цепочка кластеров:**\n\(fs.getSequenceClusters(startCluster: entry.startCluster).map{String($0+1)}.joined(separator: "->"))")
                    }
                    let name2 = fs.getLongFileName(entry: entry)
                    Text("**Полное имя (если имеются записи LFN):**\n\(asciiMode ? name2.toAsciiHex() : name2)")
                }
            } else if let entryL = entry as? EntryLong {
                VStack(alignment: .leading) {
                    Text("**LDIR_Ord:** \(entryL.ord)")
                    let name1 = asciiMode ? entryL.name_1.toAsciiHex() : entryL.name_1
                    Text("**LDIR_Name1:** \(name1)")
                    Text("**LDIR_Attr:** \(entryL.attr.rawValue.toHex())")
                    Text("**LDIR_Type:** 0")
                    let name2 = asciiMode ? entryL.name_2.toAsciiHex() : entryL.name_2
                    Text("**LDIR_Name2:** \(name2)")
                    Text("**LDIR_FstClusLO:** \(asciiMode ? (entryL.firstCluster + 1).toHex() : String(entryL.firstCluster+1))")
                    let name3 = asciiMode ? entryL.name_3.toAsciiHex() : entryL.name_3
                    Text("**LDIR_Name3:** \(name3)")
                }
            }
        }
        .onTapGesture {
            asciiMode.toggle()
        }
        .padding()
        .animation(.interactiveSpring(), value: asciiMode)
    }
}
