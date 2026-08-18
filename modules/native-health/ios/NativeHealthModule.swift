import ExpoModulesCore
import HealthKit

public class NativeHealthModule: Module {
  let store = HKHealthStore()
  public func definition() -> ModuleDefinition {
    Name("NativeHealth")
    AsyncFunction("requestPermissions") { () async throws -> Bool in
      guard HKHealthStore.isHealthDataAvailable() else { return false }
      let types: Set<HKObjectType> = [
        HKObjectType.quantityType(forIdentifier: .heartRate)!,
        HKObjectType.quantityType(forIdentifier: .oxygenSaturation)!,
        HKObjectType.quantityType(forIdentifier: .stepCount)!
      ]
      try await store.requestAuthorization(toShare: [], read: types)
      return true
    }
    AsyncFunction("readLatest") { () async throws -> [String: Any]? in
      let rows = try await readHistory(days: 1)
      return rows.sorted { ($0["timestamp"] as! String) > ($1["timestamp"] as! String) }.first
    }
    AsyncFunction("readHistory") { (days: Int) async throws -> [[String: Any]] in
      try await readHistory(days: min(max(days,1),30))
    }
  }
  private func readHistory(days: Int) async throws -> [[String: Any]] {
    let end = Date(); let start = Calendar.current.date(byAdding: .day, value: -days, to: end)!
    let hr = try await latestSamples(type: .heartRate, start: start, end: end).map { s in ["deviceId":"HEALTHKIT", "heartRate":s.quantity.doubleValue(for: HKUnit.count().unitDivided(by: .minute())), "spo2":0.0, "steps":0, "timestamp":ISO8601DateFormatter().string(from:s.startDate), "source":"healthkit"] as [String:Any] }
    let ox = try await latestSamples(type: .oxygenSaturation, start: start, end: end).map { s in ["deviceId":"HEALTHKIT", "heartRate":0.0, "spo2":s.quantity.doubleValue(for: .percent())*100, "steps":0, "timestamp":ISO8601DateFormatter().string(from:s.startDate), "source":"healthkit"] as [String:Any] }
    let st = try await latestSamples(type: .stepCount, start: start, end: end).map { s in ["deviceId":"HEALTHKIT", "heartRate":0.0, "spo2":0.0, "steps":Int(s.quantity.doubleValue(for: .count())), "timestamp":ISO8601DateFormatter().string(from:s.endDate), "source":"healthkit"] as [String:Any] }
    return hr + ox + st
  }
  private func latestSamples(type: HKQuantityTypeIdentifier, start: Date, end: Date) async throws -> [HKQuantitySample] {
    guard let q = HKObjectType.quantityType(forIdentifier: type) else { return [] }
    return try await withCheckedThrowingContinuation { cont in
      let predicate = HKQuery.predicateForSamples(withStart:start, end:end, options:.strictStartDate)
      let query = HKSampleQuery(sampleType:q, predicate:predicate, limit:1000, sortDescriptors:[NSSortDescriptor(key:HKSampleSortIdentifierStartDate, ascending:false)]) { _, samples, error in
        if let error { cont.resume(throwing:error); return }
        cont.resume(returning:(samples as? [HKQuantitySample]) ?? [])
      }
      store.execute(query)
    }
  }
}
