//
//  TickerViewModel.swift
//  01-why-modern-swift-concurrency
//
//  Created by Bogdan Pankevych on 21.04.2026.
//

import Foundation

@MainActor
class TickerViewModel: ObservableObject {
  /// Current live updates.
  @Published private(set) var tickerSymbols: [Stock] = []
  
  /// Start live updates for the provided stock symbols.
  func startTicker(_ selectedSymbols: [String]) async throws {
    guard let url = URL(string: "http://localhost:8080/littlejohn/ticker?\(selectedSymbols.joined(separator: ","))") else {
      throw "The URL could not be created."
    }
    
    let (stream, response) = try await liveURLSession.bytes(from: url)
    
    guard (response as? HTTPURLResponse)?.statusCode == 200 else {
      throw "The server responded with an error."
    }
    //    Task { @MainActor in
    //      for i in 1...1000000 {
    //          print("💚 \(i)")
    //      }
    //    }
    for try await line in stream.lines {
      let sortedSymbols = try JSONDecoder().decode([Stock].self, from: Data(line.utf8)).sorted(by: { $0.name < $1.name })
      tickerSymbols = sortedSymbols
      print("\(Thread.current)")
      //      for i in 1...1000 {
      //          print("♥️ \(i)")
      //      }
      print("Updated: \(Date())")
    }
    
    tickerSymbols = []
    
  }
  
  /// A URL session that lets requests run indefinitely so we can receive live updates from server.
  private lazy var liveURLSession: URLSession = {
    var configuration = URLSessionConfiguration.default
    configuration.timeoutIntervalForRequest = .infinity
    return URLSession(configuration: configuration)
  }()
}
