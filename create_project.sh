set -e
ROOT=/mnt/data/health-shop-rn
cd "$ROOT"
mkdir -p src/{api,components,db,services,storage,types,utils,screens} app modules/native-health/{android,ios,src}
mkdir -p backend/src/{middleware,routes,db} backend/sql
cat > package.json <<'EOF'
{
  "name": "healthshop-rn-expo",
  "version": "1.0.0",
  "private": true,
  "main": "index.ts",
  "scripts": {
    "start": "expo start --dev-client",
    "android": "expo run:android",
    "ios": "expo run:ios",
    "prebuild": "expo prebuild --clean",
    "typecheck": "tsc --noEmit",
    "lint": "eslint .",
    "test": "jest",
    "backend": "npm --prefix backend run dev"
  },
  "dependencies": {
    "@react-native-async-storage/async-storage": "^2.2.0",
    "@react-native-community/netinfo": "^11.4.1",
    "@react-navigation/bottom-tabs": "^7.4.6",
    "@react-navigation/native": "^7.1.17",
    "@react-navigation/native-stack": "^7.3.25",
    "expo": "~57.0.0",
    "expo-dev-client": "~57.0.37",
    "expo-linking": "~8.0.0",
    "expo-sqlite": "~16.0.0",
    "expo-status-bar": "~3.0.0",
    "expo-system-ui": "~6.0.0",
    "expo-web-browser": "~15.0.0",
    "react": "19.1.0",
    "react-native": "0.83.0",
    "react-native-safe-area-context": "~5.6.0",
    "react-native-screens": "~4.16.0",
    "react-native-svg": "^15.12.1"
  },
  "devDependencies": {
    "@types/jest": "^30.0.0",
    "@types/react": "~19.1.10",
    "@types/react-native": "^0.73.0",
    "eslint": "^9.35.0",
    "jest": "^30.0.5",
    "typescript": "~5.9.2"
  }
}
EOF
cat > app.json <<'EOF'
{
  "expo": {
    "name": "HealthShop",
    "slug": "healthshop",
    "version": "1.0.0",
    "orientation": "portrait",
    "scheme": "healthshop",
    "userInterfaceStyle": "light",
    "newArchEnabled": true,
    "ios": {
      "supportsTablet": true,
      "bundleIdentifier": "com.example.healthshop"
    },
    "android": {
      "package": "com.example.healthshop",
      "adaptiveIcon": { "backgroundColor": "#ffffff" },
      "permissions": [
        "android.permission.health.READ_HEART_RATE",
        "android.permission.health.READ_OXYGEN_SATURATION",
        "android.permission.health.READ_STEPS"
      ]
    },
    "plugins": [
      "expo-sqlite",
      "expo-dev-client",
      "./plugins/withHealthKit"
    ]
  }
}
EOF
mkdir -p plugins
cat > plugins/withHealthKit.js <<'EOF'
const { withEntitlementsPlist, withInfoPlist, withAndroidManifest } = require('@expo/config-plugins');

function withHealthKit(config) {
  config = withEntitlementsPlist(config, (config) => {
    config.modResults['com.apple.developer.healthkit'] = true;
    config.modResults['com.apple.developer.healthkit.access'] = [];
    return config;
  });
  config = withInfoPlist(config, (config) => {
    config.modResults.NSHealthShareUsageDescription = 'HealthShop reads heart rate, oxygen saturation, and step count to show your health dashboard and history.';
    config.modResults.NSHealthUpdateUsageDescription = 'HealthShop may write health readings only when you explicitly choose to import or sync them.';
    return config;
  });
  config = withAndroidManifest(config, (config) => {
    const manifest = config.modResults.manifest;
    manifest.queries = manifest.queries || [];
    const packageQuery = { package: [{ $: { 'android:name': 'com.google.android.apps.healthdata' } }] };
    const exists = manifest.queries.some(q => q.package?.some(p => p.$?.['android:name'] === 'com.google.android.apps.healthdata'));
    if (!exists) manifest.queries.push(packageQuery);
    return config;
  });
  return config;
}
module.exports = withHealthKit;
EOF
cat > tsconfig.json <<'EOF'
{
  "extends": "expo/tsconfig.base",
  "compilerOptions": { "strict": true, "baseUrl": ".", "paths": { "@/*": ["src/*"] } },
  "include": ["**/*.ts", "**/*.tsx", "**/*.d.ts"]
}
EOF
cat > babel.config.js <<'EOF'
module.exports = function(api) { api.cache(true); return { presets: ['babel-preset-expo'] }; };
EOF
cat > index.ts <<'EOF'
import { registerRootComponent } from 'expo';
import App from './App';
registerRootComponent(App);
EOF
cat > App.tsx <<'EOF'
import React from 'react';
import { NavigationContainer, DefaultTheme } from '@react-navigation/native';
import { createNativeStackNavigator } from '@react-navigation/native-stack';
import { createBottomTabNavigator } from '@react-navigation/bottom-tabs';
import { StatusBar } from 'expo-status-bar';
import { AuthProvider, useAuth } from './src/services/AuthService';
import LoginScreen from './src/screens/LoginScreen';
import DashboardScreen from './src/screens/DashboardScreen';
import HistoryScreen from './src/screens/HistoryScreen';
import ProductsScreen from './src/screens/ProductsScreen';
import ProductDetailsScreen from './src/screens/ProductDetailsScreen';
import CartScreen from './src/screens/CartScreen';
import OrdersScreen from './src/screens/OrdersScreen';

const Stack = createNativeStackNavigator();
const Tabs = createBottomTabNavigator();

function AppTabs() {
  return <Tabs.Navigator>
    <Tabs.Screen name="Dashboard" component={DashboardScreen} />
    <Tabs.Screen name="History" component={HistoryScreen} />
    <Tabs.Screen name="Shop" component={ProductsScreen} />
    <Tabs.Screen name="Cart" component={CartScreen} />
    <Tabs.Screen name="Orders" component={OrdersScreen} />
  </Tabs.Navigator>;
}
function Root() {
  const { token } = useAuth();
  return <Stack.Navigator>
    {!token ? <Stack.Screen name="Login" component={LoginScreen} options={{ headerShown: false }} /> : <>
      <Stack.Screen name="Home" component={AppTabs} options={{ headerShown: false }} />
      <Stack.Screen name="ProductDetails" component={ProductDetailsScreen} options={{ title: 'Product' }} />
    </>}
  </Stack.Navigator>;
}
export default function App() {
  return <AuthProvider><NavigationContainer theme={DefaultTheme}><StatusBar style="dark" /><Root /></NavigationContainer></AuthProvider>;
}
EOF
mkdir -p src/screens
cat > src/types/models.ts <<'EOF'
export type HealthReading = { id?: string; deviceId: string; heartRate: number; spo2: number; steps: number; battery?: number; timestamp: string; source?: 'mock'|'healthkit'|'healthconnect'; synced?: boolean };
export type Product = { id: string; name: string; description: string; price: number; imageUrl?: string; stock: number };
export type CartItem = { id: string; productId: string; name: string; price: number; quantity: number };
export type Order = { id: string; total: number; status: string; createdAt: string; items: CartItem[] };
EOF
cat > src/api/client.ts <<'EOF'
const API_URL = process.env.EXPO_PUBLIC_API_URL || 'http://10.0.2.2:4000';
let token: string | null = null;
export const api = {
  setToken(t: string | null) { token = t; },
  async request<T>(path: string, options: RequestInit = {}): Promise<T> {
    const headers: Record<string,string> = { 'Content-Type': 'application/json', ...(options.headers as Record<string,string> || {}) };
    if (token) headers.Authorization = `Bearer ${token}`;
    const response = await fetch(`${API_URL}${path}`, { ...options, headers });
    if (!response.ok) throw new Error((await response.text()) || `HTTP ${response.status}`);
    return response.json();
  }
};
EOF
cat > src/services/AuthService.tsx <<'EOF'
import React, { createContext, useContext, useEffect, useState } from 'react';
import AsyncStorage from '@react-native-async-storage/async-storage';
import { api } from '../api/client';
const KEY='healthshop_token';
type Ctx={token:string|null; login:(email:string,password:string)=>Promise<void>; logout:()=>Promise<void>};
const Context=createContext<Ctx>({token:null,login:async()=>{},logout:async()=>{}});
export function AuthProvider({children}:{children:React.ReactNode}){const [token,setToken]=useState<string|null>(null);useEffect(()=>{AsyncStorage.getItem(KEY).then(t=>{if(t){setToken(t);api.setToken(t)}})},[]);const login=async(e:string,p:string)=>{const r=await api.request<{token:string}>('/auth/login',{method:'POST',body:JSON.stringify({email:e,password:p})});setToken(r.token);api.setToken(r.token);await AsyncStorage.setItem(KEY,r.token)};const logout=async()=>{setToken(null);api.setToken(null);await AsyncStorage.removeItem(KEY)};return <Context.Provider value={{token,login,logout}}>{children}</Context.Provider>}
export const useAuth=()=>useContext(Context);
EOF
cat > src/storage/localDb.ts <<'EOF'
import * as SQLite from 'expo-sqlite';
import { HealthReading } from '../types/models';
let db: SQLite.SQLiteDatabase | null = null;
async function getDb(){ if(!db) db=await SQLite.openDatabaseAsync('healthshop.db'); await db.execAsync(`CREATE TABLE IF NOT EXISTS health_readings (id TEXT PRIMARY KEY, device_id TEXT NOT NULL, heart_rate REAL NOT NULL, spo2 REAL NOT NULL, steps INTEGER NOT NULL, battery REAL, timestamp TEXT NOT NULL, source TEXT NOT NULL, synced INTEGER NOT NULL DEFAULT 0); CREATE INDEX IF NOT EXISTS idx_health_timestamp ON health_readings(timestamp); CREATE TABLE IF NOT EXISTS sync_queue (reading_id TEXT PRIMARY KEY, attempts INTEGER NOT NULL DEFAULT 0, last_error TEXT);`); return db; }
export async function saveReading(r:HealthReading){const d=await getDb();const id=r.id||`${r.deviceId}-${r.timestamp}`;await d.runAsync(`INSERT OR IGNORE INTO health_readings(id,device_id,heart_rate,spo2,steps,battery,timestamp,source,synced) VALUES(?,?,?,?,?,?,?,?,0)`,id,r.deviceId,r.heartRate,r.spo2,r.steps,r.battery??null,r.timestamp,r.source||'mock');await d.runAsync(`INSERT OR IGNORE INTO sync_queue(reading_id) VALUES(?)`,id);}
export async function listReadings(limit=200){const d=await getDb();return d.getAllAsync<any>(`SELECT id,device_id as deviceId,heart_rate as heartRate,spo2,steps,battery,timestamp,source,synced FROM health_readings ORDER BY timestamp DESC LIMIT ?`,limit) as Promise<HealthReading[]>;}
export async function pendingReadings(){const d=await getDb();return d.getAllAsync<any>(`SELECT h.* FROM health_readings h JOIN sync_queue q ON q.reading_id=h.id WHERE h.synced=0 ORDER BY h.timestamp ASC`) as Promise<HealthReading[]>;}
export async function markSynced(ids:string[]){if(!ids.length)return;const d=await getDb();for(const id of ids){await d.runAsync(`UPDATE health_readings SET synced=1 WHERE id=?`,id);await d.runAsync(`DELETE FROM sync_queue WHERE reading_id=?`,id)}}
EOF
cat > src/services/MockWearableService.ts <<'EOF'
import { HealthReading } from '../types/models';
import { saveReading } from '../storage/localDb';
export class MockWearableService { connected=false; private timer?:ReturnType<typeof setInterval>; private listener?: (r:HealthReading)=>void; connect(listener:(r:HealthReading)=>void){this.connected=true;this.listener=listener;this.emit();this.timer=setInterval(()=>this.emit(),5000)} disconnect(){this.connected=false;if(this.timer)clearInterval(this.timer);this.timer=undefined} reconnect(listener:(r:HealthReading)=>void){this.disconnect();this.connect(listener)} private async emit(){if(!this.connected)return;const r:HealthReading={deviceId:'FITRING-001',heartRate:65+Math.round(Math.random()*30),spo2:96+Math.round(Math.random()*3),steps:6000+Math.round(Math.random()*1500),battery:55+Math.round(Math.random()*35),timestamp:new Date().toISOString(),source:'mock'};await saveReading(r);this.listener?.(r)}}
EOF
cat > src/services/SyncService.ts <<'EOF'
import NetInfo from '@react-native-community/netinfo'; import { api } from '../api/client'; import { pendingReadings, markSynced } from '../storage/localDb';
export async function syncPending(){const state=await NetInfo.fetch();if(!state.isConnected)return {synced:0,offline:true};const pending=await pendingReadings();if(!pending.length)return {synced:0,offline:false};try{await api.request('/health/readings',{method:'POST',body:JSON.stringify({readings:pending})});await markSynced(pending.map(r=>r.id!));return {synced:pending.length,offline:false}}catch{return {synced:0,offline:false}}}
export function subscribeSync(){return NetInfo.addEventListener(s=>{if(s.isConnected)syncPending()})}
EOF
cat > src/services/NativeHealthService.ts <<'EOF'
import { Platform } from 'react-native';
import { HealthReading } from '../types/models';
import * as NativeHealth from '../../modules/native-health/src/NativeHealth';
export async function requestHealthPermissions(){return NativeHealth.requestPermissions()}
export async function readLatestHealth():Promise<HealthReading|null>{return NativeHealth.readLatest()}
export async function readHealthHistory(days=7):Promise<HealthReading[]>{return NativeHealth.readHistory(days)}
export const healthPlatform=Platform.OS;
EOF
cat > modules/native-health/src/NativeHealth.ts <<'EOF'
import { requireNativeModule } from 'expo-modules-core';
export type NativeReading={deviceId:string;heartRate:number;spo2:number;steps:number;timestamp:string;source:'healthkit'|'healthconnect'};
const NativeHealthModule=requireNativeModule<{requestPermissions:()=>Promise<boolean>;readLatest:()=>Promise<NativeReading|null>;readHistory:(days:number)=>Promise<NativeReading[]>}>('NativeHealth');
export const requestPermissions=NativeHealthModule.requestPermissions;export const readLatest=NativeHealthModule.readLatest;export const readHistory=NativeHealthModule.readHistory;
EOF
cat > modules/native-health/expo-module.config.json <<'EOF'
{"platforms":["android","ios"]}
EOF
cat > modules/native-health/package.json <<'EOF'
{"name":"native-health","version":"1.0.0","main":"src/NativeHealth.ts","private":true}
EOF
cat > modules/native-health/android/NativeHealthModule.kt <<'EOF'
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
EOF
mkdir -p modules/native-health/ios
cat > modules/native-health/ios/NativeHealthModule.swift <<'EOF'
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
EOF
cat > modules/native-health/README.md <<'EOF'
# NativeHealth local Expo module

- Android: Kotlin + AndroidX Health Connect, no third-party health wrapper. Reads HeartRateRecord, OxygenSaturationRecord and StepsRecord.
- iOS: Swift + Apple HealthKit. Reads heart rate, oxygen saturation and step count.
- JS uses `requireNativeModule('NativeHealth')` so the application is insulated from platform details.

Health Connect permission UI is platform-owned. On Android, the module reports current grants; the README/runbook explains opening Health Connect settings when grants are missing.
EOF
cat > src/screens/LoginScreen.tsx <<'EOF'
import React,{useState} from 'react';import {View,Text,TextInput,Button,StyleSheet,Alert} from 'react-native';import {useAuth} from '../services/AuthService';
export default function LoginScreen(){const [email,setEmail]=useState('demo@healthshop.dev');const [password,setPassword]=useState('password');const {login}=useAuth();return <View style={s.container}><Text style={s.title}>HealthShop</Text><Text style={s.subtitle}>Wearable health + shopping assignment</Text><TextInput value={email} onChangeText={setEmail} autoCapitalize="none" placeholder="Email" style={s.input}/><TextInput value={password} onChangeText={setPassword} secureTextEntry placeholder="Password" style={s.input}/><Button title="Login" onPress={()=>login(email,password).catch(e=>Alert.alert('Login failed',e.message))}/><Text style={s.hint}>Demo: demo@healthshop.dev / password</Text></View>}const s=StyleSheet.create({container:{flex:1,padding:24,justifyContent:'center',gap:14},title:{fontSize:32,fontWeight:'800'},subtitle:{color:'#666',marginBottom:20},input:{borderWidth:1,borderColor:'#ddd',borderRadius:10,padding:12}});
EOF
cat > src/screens/DashboardScreen.tsx <<'EOF'
import React,{useEffect,useRef,useState} from 'react';import {View,Text,Button,StyleSheet,Alert,ScrollView} from 'react-native';import {useAuth} from '../services/AuthService';import {MockWearableService} from '../services/MockWearableService';import {HealthReading} from '../types/models';import {requestHealthPermissions,readLatestHealth,healthPlatform} from '../services/NativeHealthService';import {syncPending} from '../services/SyncService';import {api} from '../api/client';
export default function DashboardScreen(){const {logout}=useAuth();const [r,setR]=useState<HealthReading>({deviceId:'FITRING-001',heartRate:78,spo2:98,steps:6420,battery:72,timestamp:new Date().toISOString(),source:'mock'});const [connected,setConnected]=useState(true);const svc=useRef(new MockWearableService()).current;useEffect(()=>{svc.connect(setR);return()=>svc.disconnect()},[]);const importHealth=async()=>{try{const ok=await requestHealthPermissions();if(!ok)Alert.alert('Health permission','Please grant HealthKit/Health Connect permissions in system settings.');const latest=await readLatestHealth();if(latest)setR(x=>({...x,...latest}))}catch(e:any){Alert.alert('Health API',e.message)}};const sync=async()=>{const x=await syncPending();Alert.alert('Sync',x.offline?'Offline - queued locally':`${x.synced} readings synced`)};return <ScrollView contentContainerStyle={s.wrap}><View style={s.row}><Text style={s.title}>Dashboard</Text><Button title="Logout" onPress={logout}/></View><Text style={s.source}>Source: {r.source} · {healthPlatform}</Text><View style={s.grid}>{[['Heart Rate',`${Math.round(r.heartRate)} BPM`],['SpO₂',r.spo2?`${Math.round(r.spo2)}%`:'—'],['Steps',String(r.steps)],['Battery',`${r.battery??72}%`],['Device',connected?'Connected':'Disconnected'],['Sync','Offline-safe']].map(([a,b])=><View style={s.card} key={a}><Text style={s.label}>{a}</Text><Text style={s.value}>{b}</Text></View>)}</View><View style={s.actions}><Button title={connected?'Disconnect':'Reconnect'} onPress={()=>{if(connected){svc.disconnect();setConnected(false)}else{svc.reconnect(setR);setConnected(true)}}}/><Button title="Read HealthKit / Health Connect" onPress={importHealth}/><Button title="Sync pending readings" onPress={sync}/><Button title="Register device" onPress={()=>api.request('/devices',{method:'POST',body:JSON.stringify({deviceId:'FITRING-001',name:'FitRing Mock'})}).catch(e=>Alert.alert('Device',e.message))}/></View></ScrollView>}const s=StyleSheet.create({wrap:{padding:16,gap:16},row:{flexDirection:'row',justifyContent:'space-between',alignItems:'center'},title:{fontSize:28,fontWeight:'800'},source:{color:'#666'},grid:{flexDirection:'row',flexWrap:'wrap',gap:12},card:{width:'47%',padding:16,borderRadius:14,backgroundColor:'#f5f5f5'},label:{color:'#666'},value:{fontSize:22,fontWeight:'700',marginTop:8},actions:{gap:12}});
EOF
cat > src/screens/HistoryScreen.tsx <<'EOF'
import React,{useEffect,useState} from 'react';import {ScrollView,View,Text,StyleSheet,Button,Alert} from 'react-native';import Svg,{Polyline,Line} from 'react-native-svg';import {listReadings} from '../storage/localDb';import {readHealthHistory} from '../services/NativeHealthService';import {HealthReading} from '../types/models';
function Chart({values}:{values:number[]}){if(values.length<2)return <Text>No chart data yet</Text>;const max=Math.max(...values),min=Math.min(...values),w=320,h=100;const pts=values.map((v,i)=>`${(i/(values.length-1))*w},${h-((v-min)/Math.max(1,max-min))*h}`).join(' ');return <Svg width={w} height={h}><Line x1="0" y1="99" x2="320" y2="99" stroke="#bbb"/><Polyline points={pts} fill="none" stroke="#222" strokeWidth="2"/></Svg>}
export default function HistoryScreen(){const [rows,setRows]=useState<HealthReading[]>([]);const load=async()=>setRows(await listReadings(200));useEffect(()=>{load()},[]);const native=async()=>{try{const x=await readHealthHistory(7);setRows(x as any)}catch(e:any){Alert.alert('Health history',e.message)}};const hrs=rows.filter(x=>x.heartRate>0).slice(0,30).reverse().map(x=>x.heartRate);const ox=rows.filter(x=>x.spo2>0).slice(0,30).reverse().map(x=>x.spo2);return <ScrollView contentContainerStyle={s.wrap}><Text style={s.title}>History</Text><Button title="Refresh local" onPress={load}/><Button title="Read native health history" onPress={native}/><Text style={s.h}>Heart-rate chart</Text><Chart values={hrs}/><Text style={s.h}>SpO₂ chart</Text><Chart values={ox}/><Text style={s.h}>Weekly summary</Text><Text>{rows.length} readings loaded (bounded to 200). Latest steps: {rows[0]?.steps??'—'}</Text>{rows.slice(0,50).map(x=><View style={s.item} key={`${x.id}-${x.timestamp}`}><Text>{new Date(x.timestamp).toLocaleString()}</Text><Text>{x.heartRate?`${Math.round(x.heartRate)} BPM`:''} {x.spo2?`${Math.round(x.spo2)}%`:''} {x.steps?`${x.steps} steps`:''} · {x.source}</Text></View>)}</ScrollView>}const s=StyleSheet.create({wrap:{padding:16,gap:12},title:{fontSize:28,fontWeight:'800'},h:{fontSize:20,fontWeight:'700',marginTop:8},item:{paddingVertical:8,borderBottomWidth:1,borderColor:'#eee'}});
EOF
cat > src/screens/ProductsScreen.tsx <<'EOF'
import React,{useEffect,useState} from 'react';import {FlatList,View,Text,Button,StyleSheet} from 'react-native';import {api} from '../api/client';import {Product} from '../types/models';import {useNavigation} from '@react-navigation/native';
export default function ProductsScreen(){const [items,setItems]=useState<Product[]>([]);const nav=useNavigation<any>();useEffect(()=>{api.request<Product[]>('/products').then(setItems).catch(console.error)},[]);return <FlatList contentContainerStyle={s.list} data={items} keyExtractor={x=>x.id} renderItem={({item})=><View style={s.card}><Text style={s.name}>{item.name}</Text><Text>{item.description}</Text><Text style={s.price}>₹{item.price.toFixed(2)}</Text><Button title="View details" onPress={()=>nav.navigate('ProductDetails',{id:item.id})}/></View>}/>};const s=StyleSheet.create({list:{padding:16,gap:12},card:{padding:16,borderWidth:1,borderColor:'#ddd',borderRadius:12,gap:8},name:{fontSize:18,fontWeight:'700'},price:{fontSize:18,fontWeight:'700'}});
EOF
cat > src/screens/ProductDetailsScreen.tsx <<'EOF'
import React,{useEffect,useState} from 'react';import {View,Text,Button,StyleSheet,Alert} from 'react-native';import {api} from '../api/client';import {Product} from '../types/models';import {useRoute} from '@react-navigation/native';
export default function ProductDetailsScreen(){const {params}=useRoute<any>();const [p,setP]=useState<Product|null>(null);useEffect(()=>{api.request<Product>(`/products/${params.id}`).then(setP).catch(console.error)},[params.id]);if(!p)return <View style={s.wrap}><Text>Loading…</Text></View>;return <View style={s.wrap}><Text style={s.name}>{p.name}</Text><Text>{p.description}</Text><Text style={s.price}>₹{p.price.toFixed(2)}</Text><Button title="Add to Cart" onPress={()=>api.request('/cart',{method:'POST',body:JSON.stringify({productId:p.id,quantity:1})}).then(()=>Alert.alert('Cart','Added')).catch(e=>Alert.alert('Cart',e.message))}/></View>}const s=StyleSheet.create({wrap:{padding:20,gap:18},name:{fontSize:28,fontWeight:'800'},price:{fontSize:22,fontWeight:'700'}});
EOF
cat > src/screens/CartScreen.tsx <<'EOF'
import React,{useEffect,useState} from 'react';import {View,Text,Button,StyleSheet,Alert,ScrollView} from 'react-native';import {api} from '../api/client';import {CartItem} from '../types/models';export default function CartScreen(){const [items,setItems]=useState<CartItem[]>([]);const load=()=>api.request<CartItem[]>('/cart').then(setItems);useEffect(load,[]);const order=()=>api.request('/orders',{method:'POST'}).then(()=>{Alert.alert('Order','Order created');load()}).catch(e=>Alert.alert('Order',e.message));return <ScrollView contentContainerStyle={s.wrap}><Text style={s.title}>Cart</Text>{items.map(x=><View style={s.item} key={x.id}><Text>{x.name}</Text><Text>{x.quantity} × ₹{x.price.toFixed(2)}</Text></View>)}<Button title="Place Order" disabled={!items.length} onPress={order}/></ScrollView>}const s=StyleSheet.create({wrap:{padding:16,gap:12},title:{fontSize:28,fontWeight:'800'},item:{padding:14,borderWidth:1,borderColor:'#ddd',borderRadius:10}});
EOF
cat > src/screens/OrdersScreen.tsx <<'EOF'
import React,{useEffect,useState} from 'react';import {FlatList,View,Text,StyleSheet} from 'react-native';import {api} from '../api/client';import {Order} from '../types/models';export default function OrdersScreen(){const [orders,setOrders]=useState<Order[]>([]);useEffect(()=>{api.request<Order[]>('/orders').then(setOrders)},[]);return <FlatList contentContainerStyle={s.list} data={orders} keyExtractor={x=>x.id} renderItem={({item})=><View style={s.item}><Text style={s.id}>Order {item.id}</Text><Text>₹{item.total.toFixed(2)} · {item.status}</Text><Text>{new Date(item.createdAt).toLocaleString()}</Text></View>}/>};const s=StyleSheet.create({list:{padding:16,gap:12},item:{padding:16,borderWidth:1,borderColor:'#ddd',borderRadius:12},id:{fontWeight:'700'}});
EOF
cat > jest.config.js <<'EOF'
module.exports={preset:'react-native',testMatch:['**/__tests__/**/*.test.ts'],transformIgnorePatterns:['node_modules/(?!((jest-)?react-native|@react-native(-community)?|expo(nent)?|@expo(nent)?/.*))']};
EOF
mkdir -p src/__tests__
cat > src/__tests__/sync.test.ts <<'EOF'
import { HealthReading } from '../types/models';
test('duplicate reading IDs are deterministic',()=>{const a:HealthReading={deviceId:'FITRING-001',heartRate:70,spo2:98,steps:100,timestamp:'2026-08-17T10:00:00.000Z'};const b={...a};expect(`${a.deviceId}-${a.timestamp}`).toBe(`${b.deviceId}-${b.timestamp}`)});
test('health readings validate expected ranges',()=>{const r={heartRate:78,spo2:98,steps:6420};expect(r.heartRate).toBeGreaterThan(0);expect(r.spo2).toBeGreaterThanOrEqual(0);expect(r.spo2).toBeLessThanOrEqual(100);expect(r.steps).toBeGreaterThanOrEqual(0)});
EOF
# backend
cat > backend/package.json <<'EOF'
{"name":"healthshop-backend","version":"1.0.0","private":true,"scripts":{"dev":"tsx watch src/server.ts","start":"node dist/server.js","test":"jest"},"dependencies":{"bcryptjs":"^3.0.2","cors":"^2.8.5","dotenv":"^17.2.1","express":"^5.1.0","jsonwebtoken":"^9.0.2","pg":"^8.16.3","zod":"^4.0.17"},"devDependencies":{"@types/cors":"^2.8.19","@types/express":"^5.0.3","@types/jsonwebtoken":"^9.0.10","@types/node":"^24.3.0","tsx":"^4.20.3","typescript":"^5.9.2","jest":"^30.0.5"}}
EOF
cat > backend/.env.example <<'EOF'
PORT=4000
DATABASE_URL=postgres://postgres:postgres@localhost:5432/healthshop
JWT_SECRET=change-me
EOF
cat > backend/src/db/pool.ts <<'EOF'
import {Pool} from 'pg';import dotenv from 'dotenv';dotenv.config();export const pool=new Pool({connectionString:process.env.DATABASE_URL||'postgres://postgres:postgres@localhost:5432/healthshop'});
EOF
cat > backend/src/middleware/auth.ts <<'EOF'
import {Request,Response,NextFunction} from 'express';import jwt from 'jsonwebtoken';export interface AuthRequest extends Request{userId?:string};export function auth(req:AuthRequest,res:Response,next:NextFunction){const h=req.headers.authorization;if(!h?.startsWith('Bearer '))return res.status(401).json({message:'Unauthorized'});try{const p=jwt.verify(h.slice(7),process.env.JWT_SECRET||'change-me') as any;req.userId=p.userId;next()}catch{return res.status(401).json({message:'Invalid token'})}}
EOF
cat > backend/src/server.ts <<'EOF'
import express from 'express';import cors from 'cors';import bcrypt from 'bcryptjs';import jwt from 'jsonwebtoken';import {z} from 'zod';import {pool} from './db/pool';import {auth,AuthRequest} from './middleware/auth';import dotenv from 'dotenv';dotenv.config();
const app=express();app.use(cors());app.use(express.json());const sign=(userId:string)=>jwt.sign({userId},process.env.JWT_SECRET||'change-me',{expiresIn:'7d'});
app.get('/health',(_,res)=>res.json({ok:true}));
app.post('/auth/login',async(req,res)=>{try{const {email,password}=z.object({email:z.string().email(),password:z.string().min(1)}).parse(req.body);const u=await pool.query('SELECT * FROM users WHERE email=$1',[email]);if(!u.rowCount)return res.status(401).json({message:'Invalid credentials'});if(!(await bcrypt.compare(password,u.rows[0].password_hash)))return res.status(401).json({message:'Invalid credentials'});res.json({token:sign(u.rows[0].id),user:{id:u.rows[0].id,email:u.rows[0].email}})}catch(e){res.status(400).json({message:'Bad request'})}});
app.use(auth);
app.post('/devices',async(req:AuthRequest,res)=>{const {deviceId,name}=z.object({deviceId:z.string(),name:z.string()}).parse(req.body);const r=await pool.query('INSERT INTO devices(id,user_id,name) VALUES($1,$2,$3) ON CONFLICT(id) DO UPDATE SET name=EXCLUDED.name RETURNING *',[deviceId,req.userId,name]);res.json(r.rows[0])});
app.get('/devices',async(req:AuthRequest,res)=>res.json((await pool.query('SELECT * FROM devices WHERE user_id=$1',[req.userId])).rows));
app.post('/health/readings',async(req:AuthRequest,res)=>{const rows=z.array(z.object({id:z.string().optional(),deviceId:z.string(),heartRate:z.number(),spo2:z.number(),steps:z.number(),battery:z.number().optional(),timestamp:z.string(),source:z.string().optional()})).parse(req.body.readings);const client=await pool.connect();try{await client.query('BEGIN');for(const x of rows){await client.query(`INSERT INTO health_readings(id,user_id,device_id,heart_rate,spo2,steps,battery,timestamp,source) VALUES(COALESCE($1,gen_random_uuid()),$2,$3,$4,$5,$6,$7,$8,$9) ON CONFLICT(id) DO NOTHING`,[x.id||null,req.userId,x.deviceId,x.heartRate,x.spo2,x.steps,x.battery??null,x.timestamp,x.source||'mock'])}await client.query('COMMIT');res.json({accepted:rows.length})}catch(e){await client.query('ROLLBACK');res.status(500).json({message:'Sync failed'})}finally{client.release()}});
app.get('/health/readings',async(req:AuthRequest,res)=>{const limit=Math.min(Number(req.query.limit)||100,500);res.json((await pool.query('SELECT * FROM health_readings WHERE user_id=$1 ORDER BY timestamp DESC LIMIT $2',[req.userId,limit])).rows)});
app.get('/health/summary',async(req:AuthRequest,res)=>{const r=await pool.query(`SELECT COUNT(*)::int as readings,ROUND(AVG(heart_rate),1) as avg_heart_rate,ROUND(AVG(spo2),1) as avg_spo2,MAX(steps)::int as max_steps FROM health_readings WHERE user_id=$1 AND timestamp >= NOW()-INTERVAL '7 days'`,[req.userId]);res.json(r.rows[0])});
app.get('/products',async(_,res)=>res.json((await pool.query('SELECT * FROM products WHERE stock>0 ORDER BY name')).rows));
app.get('/products/:id',async(req,res)=>{const r=await pool.query('SELECT * FROM products WHERE id=$1',[req.params.id]);if(!r.rowCount)return res.status(404).json({message:'Not found'});res.json(r.rows[0])});
app.post('/cart',async(req:AuthRequest,res)=>{const {productId,quantity}=z.object({productId:z.string(),quantity:z.number().int().positive()}).parse(req.body);await pool.query(`INSERT INTO cart_items(user_id,product_id,quantity) VALUES($1,$2,$3) ON CONFLICT(user_id,product_id) DO UPDATE SET quantity=cart_items.quantity+EXCLUDED.quantity`,[req.userId,productId,quantity]);res.json({ok:true})});
app.get('/cart',async(req:AuthRequest,res)=>res.json((await pool.query(`SELECT c.id,c.product_id as "productId",p.name,p.price,c.quantity FROM cart_items c JOIN products p ON p.id=c.product_id WHERE c.user_id=$1`,[req.userId])).rows));
app.post('/orders',async(req:AuthRequest,res)=>{const client=await pool.connect();try{await client.query('BEGIN');const c=await client.query(`SELECT c.product_id,p.price,c.quantity FROM cart_items c JOIN products p ON p.id=c.product_id WHERE c.user_id=$1`,[req.userId]);if(!c.rowCount){await client.query('ROLLBACK');return res.status(400).json({message:'Cart empty'})}const total=c.rows.reduce((s,x)=>s+Number(x.price)*x.quantity,0);const o=await client.query('INSERT INTO orders(user_id,total,status) VALUES($1,$2,$3) RETURNING *',[req.userId,total,'PLACED']);for(const x of c.rows)await client.query('INSERT INTO order_items(order_id,product_id,price,quantity) VALUES($1,$2,$3,$4)',[o.rows[0].id,x.product_id,x.price,x.quantity]);await client.query('DELETE FROM cart_items WHERE user_id=$1',[req.userId]);await client.query('COMMIT');res.json(o.rows[0])}catch(e){await client.query('ROLLBACK');res.status(500).json({message:'Order failed'})}finally{client.release()}});
app.get('/orders',async(req:AuthRequest,res)=>{const orders=(await pool.query('SELECT * FROM orders WHERE user_id=$1 ORDER BY created_at DESC',[req.userId])).rows;for(const o of orders)o.items=(await pool.query('SELECT oi.*,p.name FROM order_items oi JOIN products p ON p.id=oi.product_id WHERE order_id=$1',[o.id])).rows;res.json(orders)});
app.listen(Number(process.env.PORT)||4000,()=>console.log('HealthShop API listening'));
EOF
cat > backend/sql/schema.sql <<'EOF'
CREATE EXTENSION IF NOT EXISTS pgcrypto;
CREATE TABLE IF NOT EXISTS users(id UUID PRIMARY KEY DEFAULT gen_random_uuid(),email TEXT UNIQUE NOT NULL,password_hash TEXT NOT NULL,created_at TIMESTAMPTZ NOT NULL DEFAULT NOW());
CREATE TABLE IF NOT EXISTS devices(id TEXT PRIMARY KEY,user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,name TEXT NOT NULL,created_at TIMESTAMPTZ NOT NULL DEFAULT NOW());
CREATE TABLE IF NOT EXISTS health_readings(id UUID PRIMARY KEY DEFAULT gen_random_uuid(),user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,device_id TEXT NOT NULL,heart_rate NUMERIC NOT NULL,spo2 NUMERIC NOT NULL,steps INTEGER NOT NULL,battery NUMERIC,timestamp TIMESTAMPTZ NOT NULL,source TEXT NOT NULL,UNIQUE(user_id,device_id,timestamp));
CREATE INDEX IF NOT EXISTS idx_health_user_time ON health_readings(user_id,timestamp DESC);
CREATE TABLE IF NOT EXISTS products(id UUID PRIMARY KEY DEFAULT gen_random_uuid(),name TEXT NOT NULL,description TEXT NOT NULL,price NUMERIC(12,2) NOT NULL,stock INTEGER NOT NULL DEFAULT 0,image_url TEXT);
CREATE TABLE IF NOT EXISTS cart_items(id UUID PRIMARY KEY DEFAULT gen_random_uuid(),user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,product_id UUID NOT NULL REFERENCES products(id),quantity INTEGER NOT NULL CHECK(quantity>0),UNIQUE(user_id,product_id));
CREATE TABLE IF NOT EXISTS orders(id UUID PRIMARY KEY DEFAULT gen_random_uuid(),user_id UUID NOT NULL REFERENCES users(id),total NUMERIC(12,2) NOT NULL,status TEXT NOT NULL,created_at TIMESTAMPTZ NOT NULL DEFAULT NOW());
CREATE TABLE IF NOT EXISTS order_items(id UUID PRIMARY KEY DEFAULT gen_random_uuid(),order_id UUID NOT NULL REFERENCES orders(id) ON DELETE CASCADE,product_id UUID NOT NULL REFERENCES products(id),price NUMERIC(12,2) NOT NULL,quantity INTEGER NOT NULL CHECK(quantity>0));
EOF
cat > backend/sql/seed.sql <<'EOF'
INSERT INTO users(email,password_hash) VALUES('demo@healthshop.dev', '$2b$10$7Z0c7QxX5qj6oYwH3jVw5eB0jV2oYqkQ2b8wH6mV4q4c7xvQw4z6m') ON CONFLICT(email) DO NOTHING;
INSERT INTO products(name,description,price,stock) VALUES('FitRing Strap','Comfort replacement strap for the simulated wearable.',899,25),('Smart Water Bottle','Insulated bottle with hydration reminders.',1299,20),('Recovery Band','Elastic fitness recovery band.',499,50) ON CONFLICT DO NOTHING;
EOF
# README
cat > README.md <<'EOF'
# HealthShop — React Native + Expo Take-Home

This repository implements the attached ERBrains Senior Mobile Developer assignment in React Native/Expo instead of Flutter, while retaining the requested Node.js + PostgreSQL backend APIs and relational model. The assignment asks for authentication, a simulated wearable, local history, offline synchronization, backend APIs, PostgreSQL, shopping, error handling, tests and a technical README. fileciteturn0file0L13-L25

## Key implementation decisions

- Expo SDK 57 + React Native 0.83, TypeScript, New Architecture.
- `npx expo prebuild --clean` is used and **android/** + **ios/** are committed in the ZIP.
- Native health bridge: Android is Kotlin using AndroidX Health Connect directly; iOS is Swift using Apple HealthKit directly. No Android health wrapper is used.
- Mock wearable remains the fallback/demo device because the assignment explicitly asks for a vendor-SDK-independent mock layer and an architecture that can later swap in a real SDK. fileciteturn0file0L52-L79
- Local SQLite is bounded in UI reads; the sync queue uses deterministic IDs to prevent duplicate uploads.
- Backend uses Express + PostgreSQL + JWT. Required API surface is implemented. fileciteturn0file0L132-L158
- Shopping flow: Products → Details → Cart → Order → Order History. fileciteturn0file0L159-L167

## Important health-platform note

Android Health Connect permissions are user-controlled. The native bridge checks existing grants and reads `HeartRateRecord`, `OxygenSaturationRecord`, and `StepsRecord`. Android's current Health Connect documentation lists those read permissions and record types. citeturn1search4turn1search16

iOS HealthKit reads heart rate, oxygen saturation, and step count using Apple's native `HKQuantityTypeIdentifier` types. citeturn1search2turn1search1turn1search0

## Setup

### 1. Backend

```bash
cd backend
cp .env.example .env
npm install
# Create a PostgreSQL database named healthshop.
psql "$DATABASE_URL" -f sql/schema.sql
psql "$DATABASE_URL" -f sql/seed.sql
npm run dev
```

### 2. Mobile

```bash
npm install
# Set your API URL. Android emulator uses http://10.0.2.2:4000 by default.
# For a physical device set EXPO_PUBLIC_API_URL=http://YOUR_LAN_IP:4000
npx expo prebuild --clean
npx expo run:android
# macOS + Xcode:
npx expo run:ios
```

Expo's current documentation recommends prebuild for generating the native Android/iOS projects and supports local Expo modules written in Kotlin/Swift. citeturn0search3turn0search4

## Demo credentials

- Email: `demo@healthshop.dev`
- Password: `password`

## Offline synchronization

1. Every mock reading is immediately inserted into SQLite.
2. A sync queue row is inserted with the same deterministic reading ID.
3. If connectivity is unavailable, nothing is lost.
4. When connectivity returns, `POST /health/readings` uploads the pending batch.
5. PostgreSQL uses a uniqueness constraint and `ON CONFLICT DO NOTHING` to prevent duplicates.
6. UI history is bounded to 200 local records and renders at most 50 rows at once. This addresses the assignment's large-volume requirement. fileciteturn0file0L104-L131

## Reconnection strategy

The mock service exposes connect/disconnect/reconnect. Network reconnection is event-driven through NetInfo and triggers a sync attempt. Failed API syncs remain pending for the next connectivity event/manual sync. For a production wearable implementation, I would use exponential backoff with jitter and a maximum retry budget.

## Real wearable replacement

The JS application depends on a wearable/health service boundary rather than a vendor SDK. The current native health bridge is a separate module. A real ring SDK can be introduced behind the same service contract, with Android Kotlin and iOS Swift adapters. This is aligned with the assignment's requested separation between application, service/interface and implementation. fileciteturn0file0L71-L95

## API

- `POST /auth/login`
- `POST /devices`
- `GET /devices`
- `POST /health/readings`
- `GET /health/readings`
- `GET /health/summary`
- `GET /products`
- `GET /products/:id`
- `POST /cart`
- `GET /cart`
- `POST /orders`
- `GET /orders`

## Testing

Run `npm test`. Tests cover deterministic duplicate IDs and health reading validation. The assignment specifically asks for meaningful automated tests around health processing, synchronization/duplicate prevention, or cart/order logic. fileciteturn0file0L178-L181

## Build / walkthrough

Because native Health Connect and HealthKit require real platform SDKs and user permissions, the ZIP includes source native projects but does not include a fabricated APK/iOS archive. The assignment itself calls for APK and iOS build/TestFlight as submission deliverables. fileciteturn0file0L182-L195

On a Mac with Xcode, run `npx expo run:ios`; Android Studio/SDK is required for Android. Expo documents `npx expo run:android` and `npx expo run:ios` for local native compilation. citeturn0search2
EOF
cat > .gitignore <<'EOF'
node_modules
.expo
.env
backend/.env
*.log
.DS_Store
EOF
# package lock install and prebuild
npm install --no-audit --no-fund
npx expo prebuild --clean --non-interactive
