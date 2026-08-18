package expo.modules.nativehealth

import android.content.Context
import androidx.health.connect.client.HealthConnectClient
import androidx.health.connect.client.PermissionController
import androidx.health.connect.client.permission.HealthPermission
import androidx.health.connect.client.records.HeartRateRecord
import androidx.health.connect.client.records.OxygenSaturationRecord
import androidx.health.connect.client.records.StepsRecord
import androidx.health.connect.client.request.ReadRecordsRequest
import androidx.health.connect.client.time.TimeRangeFilter
import expo.modules.kotlin.modules.Module
import expo.modules.kotlin.modules.ModuleDefinition
import kotlinx.coroutines.runBlocking
import java.time.Instant
import java.time.temporal.ChronoUnit

class NativeHealthModule : Module() {
  private val permissions = setOf(
    HealthPermission.getReadPermission(HeartRateRecord::class),
    HealthPermission.getReadPermission(OxygenSaturationRecord::class),
    HealthPermission.getReadPermission(StepsRecord::class)
  )
  private fun client(): HealthConnectClient? = runCatching { HealthConnectClient.getOrCreate(requireNotNull(appContext.reactContext)) }.getOrNull()
  override fun definition() = ModuleDefinition {
    Name("NativeHealth")
    AsyncFunction("requestPermissions") { ->
      val c=client() ?: return@AsyncFunction false
      val provider=PermissionController.createRequestPermissionResultContract()
      // Permission UI must be launched by an ActivityResultLauncher in a host Activity. For this assignment,
      // check existing grants here and expose false when the user has not granted them yet.
      runBlocking { c.permissionController.getGrantedPermissions().containsAll(permissions) }
    }
    AsyncFunction("readLatest") { -> read(1).maxByOrNull { it["timestamp"] as String } }
    AsyncFunction("readHistory") { days: Int -> read(days.coerceIn(1,30)) }
  }
  private fun read(days:Int):List<Map<String,Any>> = runBlocking {
    val c=client() ?: return@runBlocking emptyList()
    val end=Instant.now(); val start=end.minus(days.toLong(),ChronoUnit.DAYS); val range=TimeRangeFilter.between(start,end)
    val hr=c.readRecords(ReadRecordsRequest(HeartRateRecord::class,range)).records.flatMap { it.samples }.map { mapOf("deviceId" to "HEALTH-CONNECT", "heartRate" to it.beatsPerMinute.toDouble(), "spo2" to 0.0, "steps" to 0L, "timestamp" to it.time.toString(), "source" to "healthconnect") }
    val ox=c.readRecords(ReadRecordsRequest(OxygenSaturationRecord::class,range)).records.map { mapOf("deviceId" to "HEALTH-CONNECT", "heartRate" to 0.0, "spo2" to it.percentage.value*100.0, "steps" to 0L, "timestamp" to it.time.toString(), "source" to "healthconnect") }
    val steps=c.readRecords(ReadRecordsRequest(StepsRecord::class,range)).records.map { mapOf("deviceId" to "HEALTH-CONNECT", "heartRate" to 0.0, "spo2" to 0.0, "steps" to it.count, "timestamp" to it.endTime.toString(), "source" to "healthconnect") }
    (hr+ox+steps).groupBy { it["timestamp"] }.values.map { group -> mapOf("deviceId" to "HEALTH-CONNECT", "heartRate" to (group.firstOrNull { (it["heartRate"] as Double)>0 }?.get("heartRate") ?: 0.0), "spo2" to (group.firstOrNull { (it["spo2"] as Double)>0 }?.get("spo2") ?: 0.0), "steps" to (group.firstOrNull { (it["steps"] as Long)>0 }?.get("steps") ?: 0L), "timestamp" to group.first()["timestamp"]!!, "source" to "healthconnect") }
  }
}
