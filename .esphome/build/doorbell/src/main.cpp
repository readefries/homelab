// Auto generated code by esphome
// ========== AUTO GENERATED INCLUDE BLOCK BEGIN ===========
#include "esphome.h"
using namespace esphome;
using std::isnan;
using std::min;
using std::max;
using namespace time;
using namespace text_sensor;
using namespace sensor;
using namespace switch_;
using namespace binary_sensor;
logger::Logger *logger_logger_id;
web_server_base::WebServerBase *web_server_base_webserverbase_id;
wifi::WiFiComponent *wifi_wificomponent_id;
mdns::MDNSComponent *mdns_mdnscomponent_id;
esphome::ESPHomeOTAComponent *esphome_esphomeotacomponent_id;
safe_mode::SafeModeComponent *safe_mode_safemodecomponent_id;
mqtt::MQTTClientComponent *mqtt_mqttclientcomponent_id;
using namespace mqtt;
web_server::WebServer *web_server_webserver_id;
const uint8_t ESPHOME_WEBSERVER_INDEX_HTML[174] PROGMEM = {60, 33, 68, 79, 67, 84, 89, 80, 69, 32, 104, 116, 109, 108, 62, 60, 104, 116, 109, 108, 62, 60, 104, 101, 97, 100, 62, 60, 109, 101, 116, 97, 32, 99, 104, 97, 114, 115, 101, 116, 61, 85, 84, 70, 45, 56, 62, 60, 108, 105, 110, 107, 32, 114, 101, 108, 61, 105, 99, 111, 110, 32, 104, 114, 101, 102, 61, 100, 97, 116, 97, 58, 62, 60, 47, 104, 101, 97, 100, 62, 60, 98, 111, 100, 121, 62, 60, 101, 115, 112, 45, 97, 112, 112, 62, 60, 47, 101, 115, 112, 45, 97, 112, 112, 62, 60, 115, 99, 114, 105, 112, 116, 32, 115, 114, 99, 61, 34, 104, 116, 116, 112, 115, 58, 47, 47, 111, 105, 46, 101, 115, 112, 104, 111, 109, 101, 46, 105, 111, 47, 118, 50, 47, 119, 119, 119, 46, 106, 115, 34, 62, 60, 47, 115, 99, 114, 105, 112, 116, 62, 60, 47, 98, 111, 100, 121, 62, 60, 47, 104, 116, 109, 108, 62};
const size_t ESPHOME_WEBSERVER_INDEX_HTML_SIZE = 174;
using namespace json;
preferences::IntervalSyncer *preferences_intervalsyncer_id;
sntp::SNTPComponent *sntp_time;
version::VersionTextSensor *version_versiontextsensor_id;
mqtt::MQTTTextSensor *mqtt_mqtttextsensor_id;
wifi_info::SSIDWiFiInfo *wifi_info_ssidwifiinfo_id;
mqtt::MQTTTextSensor *mqtt_mqtttextsensor_id_3;
wifi_info::BSSIDWiFiInfo *wifi_info_bssidwifiinfo_id;
mqtt::MQTTTextSensor *mqtt_mqtttextsensor_id_4;
wifi_info::IPAddressWiFiInfo *wifi_info_ipaddresswifiinfo_id;
mqtt::MQTTTextSensor *mqtt_mqtttextsensor_id_2;
uptime::UptimeSecondsSensor *uptime_uptimesecondssensor_id;
mqtt::MQTTSensorComponent *mqtt_mqttsensorcomponent_id;
wifi_signal::WiFiSignalSensor *wifi_signal_wifisignalsensor_id;
mqtt::MQTTSensorComponent *mqtt_mqttsensorcomponent_id_2;
restart::RestartSwitch *restart_restartswitch_id;
mqtt::MQTTSwitchComponent *mqtt_mqttswitchcomponent_id;
gpio::GPIOSwitch *relay;
mqtt::MQTTSwitchComponent *mqtt_mqttswitchcomponent_id_2;
esphome::esp8266::ESP8266GPIOPin *esphome_esp8266_esp8266gpiopin_id;
template_::TemplateSwitch *chime_active;
mqtt::MQTTSwitchComponent *mqtt_mqttswitchcomponent_id_3;
gpio::GPIOBinarySensor *button;
binary_sensor::DelayedOnFilter *binary_sensor_delayedonfilter_id;
binary_sensor::DelayedOffFilter *binary_sensor_delayedofffilter_id;
binary_sensor::PressTrigger *binary_sensor_presstrigger_id;
Automation<> *automation_id_3;
switch_::SwitchCondition<> *switch__switchcondition_id;
AndCondition<> *andcondition_id;
IfAction<> *ifaction_id;
switch_::TurnOnAction<> *switch__turnonaction_id;
binary_sensor::ReleaseTrigger *binary_sensor_releasetrigger_id;
Automation<> *automation_id_4;
switch_::TurnOffAction<> *switch__turnoffaction_id;
mqtt::MQTTBinarySensorComponent *mqtt_mqttbinarysensorcomponent_id;
esphome::esp8266::ESP8266GPIOPin *esphome_esp8266_esp8266gpiopin_id_2;
globals::RestoringGlobalsComponent<bool> *chime;
Automation<> *automation_id_2;
globals::GlobalVarSetAction<globals::RestoringGlobalsComponent<bool>> *globals_globalvarsetaction_id_2;
Automation<> *automation_id;
globals::GlobalVarSetAction<globals::RestoringGlobalsComponent<bool>> *globals_globalvarsetaction_id;
const uint8_t ESPHOME_ESP8266_GPIO_INITIAL_MODE[16] = {OUTPUT, 255, INPUT_PULLUP, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255};
const uint8_t ESPHOME_ESP8266_GPIO_INITIAL_LEVEL[16] = {0, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255};
#define yield() esphome::yield()
#define millis() esphome::millis()
#define micros() esphome::micros()
#define delay(x) esphome::delay(x)
#define delayMicroseconds(x) esphome::delayMicroseconds(x)
// ========== AUTO GENERATED INCLUDE BLOCK END ==========="

void setup() {
  // ========== AUTO GENERATED CODE BEGIN ===========
  // esp8266:
  //   board: esp01_1m
  //   framework:
  //     version: 3.1.2
  //     source: ~3.30102.0
  //     platform_version: platformio/espressif8266@4.2.1
  //   restore_from_flash: false
  //   early_pin_init: true
  //   board_flash_mode: dout
  esphome::esp8266::setup_preferences();
  // async_tcp:
  //   {}
  // esphome:
  //   name: doorbell
  //   min_version: 2025.2.2
  //   build_path: build/doorbell
  //   friendly_name: ''
  //   area: ''
  //   platformio_options: {}
  //   includes: []
  //   libraries: []
  //   name_add_mac_suffix: false
  App.pre_setup("doorbell", "", "", "", __DATE__ ", " __TIME__, false);
  // time:
  // text_sensor:
  // sensor:
  // switch:
  // binary_sensor:
  // logger:
  //   id: logger_logger_id
  //   baud_rate: 115200
  //   tx_buffer_size: 512
  //   deassert_rts_dtr: false
  //   hardware_uart: UART0
  //   level: DEBUG
  //   logs: {}
  //   esp8266_store_log_strings_in_flash: true
  logger_logger_id = new logger::Logger(115200, 512);
  logger_logger_id->set_log_level(ESPHOME_LOG_LEVEL_DEBUG);
  logger_logger_id->set_uart_selection(logger::UART_SELECTION_UART0);
  logger_logger_id->pre_setup();
  logger_logger_id->set_component_source("logger");
  App.register_component(logger_logger_id);
  // web_server_base:
  //   id: web_server_base_webserverbase_id
  web_server_base_webserverbase_id = new web_server_base::WebServerBase();
  web_server_base_webserverbase_id->set_component_source("web_server_base");
  App.register_component(web_server_base_webserverbase_id);
  // wifi:
  //   id: wifi_wificomponent_id
  //   domain: .local
  //   reboot_timeout: 15min
  //   power_save_mode: NONE
  //   fast_connect: false
  //   output_power: 20.0
  //   passive_scan: false
  //   enable_on_boot: true
  //   networks:
  //   - ssid: xs4some.local
  //     password: 56RZnI4NwAOqUIQX
  //     id: wifi_wifiap_id
  //     priority: 0.0
  //   use_address: doorbell.local
  wifi_wificomponent_id = new wifi::WiFiComponent();
  wifi_wificomponent_id->set_use_address("doorbell.local");
  {
  wifi::WiFiAP wifi_wifiap_id = wifi::WiFiAP();
  wifi_wifiap_id.set_ssid("xs4some.local");
  wifi_wifiap_id.set_password("56RZnI4NwAOqUIQX");
  wifi_wifiap_id.set_priority(0.0f);
  wifi_wificomponent_id->add_sta(wifi_wifiap_id);
  }
  wifi_wificomponent_id->set_reboot_timeout(900000);
  wifi_wificomponent_id->set_power_save_mode(wifi::WIFI_POWER_SAVE_NONE);
  wifi_wificomponent_id->set_fast_connect(false);
  wifi_wificomponent_id->set_passive_scan(false);
  wifi_wificomponent_id->set_output_power(20.0f);
  wifi_wificomponent_id->set_enable_on_boot(true);
  wifi_wificomponent_id->set_component_source("wifi");
  App.register_component(wifi_wificomponent_id);
  // mdns:
  //   id: mdns_mdnscomponent_id
  //   disabled: false
  //   services: []
  mdns_mdnscomponent_id = new mdns::MDNSComponent();
  mdns_mdnscomponent_id->set_component_source("mdns");
  App.register_component(mdns_mdnscomponent_id);
  // ota:
  // ota.esphome:
  //   platform: esphome
  //   id: esphome_esphomeotacomponent_id
  //   version: 2
  //   port: 8266
  esphome_esphomeotacomponent_id = new esphome::ESPHomeOTAComponent();
  esphome_esphomeotacomponent_id->set_port(8266);
  esphome_esphomeotacomponent_id->set_component_source("esphome.ota");
  App.register_component(esphome_esphomeotacomponent_id);
  // safe_mode:
  //   id: safe_mode_safemodecomponent_id
  //   boot_is_good_after: 1min
  //   disabled: false
  //   num_attempts: 10
  //   reboot_timeout: 5min
  safe_mode_safemodecomponent_id = new safe_mode::SafeModeComponent();
  safe_mode_safemodecomponent_id->set_component_source("safe_mode");
  App.register_component(safe_mode_safemodecomponent_id);
  if (safe_mode_safemodecomponent_id->should_enter_safe_mode(10, 300000, 60000)) return;
  // mqtt:
  //   broker: 172.16.3.4
  //   port: 1883
  //   discovery: true
  //   discovery_prefix: homeassistant
  //   id: mqtt_mqttclientcomponent_id
  //   enable_on_boot: true
  //   username: ''
  //   password: ''
  //   clean_session: false
  //   discovery_retain: true
  //   discover_ip: true
  //   discovery_unique_id_generator: legacy
  //   discovery_object_id_generator: none
  //   use_abbreviations: true
  //   topic_prefix: doorbell
  //   keepalive: 15s
  //   reboot_timeout: 15min
  //   publish_nan_as_none: false
  //   birth_message:
  //     topic: doorbell/status
  //     payload: online
  //     qos: 0
  //     retain: true
  //   will_message:
  //     topic: doorbell/status
  //     payload: offline
  //     qos: 0
  //     retain: true
  //   shutdown_message:
  //     topic: doorbell/status
  //     payload: offline
  //     qos: 0
  //     retain: true
  //   log_topic:
  //     topic: doorbell/debug
  //     qos: 0
  //     retain: true
  mqtt_mqttclientcomponent_id = new mqtt::MQTTClientComponent();
  mqtt_mqttclientcomponent_id->set_component_source("mqtt");
  App.register_component(mqtt_mqttclientcomponent_id);
  mqtt_mqttclientcomponent_id->set_broker_address("172.16.3.4");
  mqtt_mqttclientcomponent_id->set_enable_on_boot(true);
  mqtt_mqttclientcomponent_id->set_broker_port(1883);
  mqtt_mqttclientcomponent_id->set_username("");
  mqtt_mqttclientcomponent_id->set_password("");
  mqtt_mqttclientcomponent_id->set_clean_session(false);
  mqtt_mqttclientcomponent_id->set_discovery_info("homeassistant", mqtt::MQTT_LEGACY_UNIQUE_ID_GENERATOR, mqtt::MQTT_NONE_OBJECT_ID_GENERATOR, true, true);
  mqtt_mqttclientcomponent_id->set_topic_prefix("doorbell", "doorbell");
  mqtt_mqttclientcomponent_id->set_birth_message(mqtt::MQTTMessage{
      .topic = "doorbell/status",
      .payload = "online",
      .qos = 0,
      .retain = true,
  });
  mqtt_mqttclientcomponent_id->set_last_will(mqtt::MQTTMessage{
      .topic = "doorbell/status",
      .payload = "offline",
      .qos = 0,
      .retain = true,
  });
  mqtt_mqttclientcomponent_id->set_shutdown_message(mqtt::MQTTMessage{
      .topic = "doorbell/status",
      .payload = "offline",
      .qos = 0,
      .retain = true,
  });
  mqtt_mqttclientcomponent_id->set_log_message_template(mqtt::MQTTMessage{
      .topic = "doorbell/debug",
      .payload = "",
      .qos = 0,
      .retain = true,
  });
  mqtt_mqttclientcomponent_id->set_keep_alive(15);
  mqtt_mqttclientcomponent_id->set_reboot_timeout(900000);
  mqtt_mqttclientcomponent_id->set_publish_nan_as_none(false);
  // web_server:
  //   port: 80
  //   id: web_server_webserver_id
  //   version: 2
  //   enable_private_network_access: true
  //   web_server_base_id: web_server_base_webserverbase_id
  //   include_internal: false
  //   ota: true
  //   log: true
  //   css_url: ''
  //   js_url: https:oi.esphome.io/v2/www.js
  web_server_webserver_id = new web_server::WebServer(web_server_base_webserverbase_id);
  web_server_webserver_id->set_component_source("web_server");
  App.register_component(web_server_webserver_id);
  web_server_base_webserverbase_id->set_port(80);
  web_server_webserver_id->set_allow_ota(true);
  web_server_webserver_id->set_expose_log(true);
  web_server_webserver_id->set_include_internal(false);
  // json:
  //   {}
  // preferences:
  //   id: preferences_intervalsyncer_id
  //   flash_write_interval: 60s
  preferences_intervalsyncer_id = new preferences::IntervalSyncer();
  preferences_intervalsyncer_id->set_write_interval(60000);
  preferences_intervalsyncer_id->set_component_source("preferences");
  App.register_component(preferences_intervalsyncer_id);
  // time.sntp:
  //   platform: sntp
  //   id: sntp_time
  //   servers:
  //   - 0.nl.pool.ntp.org
  //   - 1.nl.pool.ntp.org
  //   - 2.nl.pool.ntp.org
  //   timezone: CET-1CEST,M3.5.0,M10.5.0/3
  //   update_interval: 15min
  sntp_time = new sntp::SNTPComponent({"0.nl.pool.ntp.org", "1.nl.pool.ntp.org", "2.nl.pool.ntp.org"});
  sntp_time->set_update_interval(900000);
  sntp_time->set_component_source("sntp.time");
  App.register_component(sntp_time);
  sntp_time->set_timezone("CET-1CEST,M3.5.0,M10.5.0/3");
  // text_sensor.version:
  //   platform: version
  //   name: Doorbell ESPHome Version
  //   disabled_by_default: false
  //   mqtt_id: mqtt_mqtttextsensor_id
  //   icon: mdi:new-box
  //   entity_category: diagnostic
  //   id: version_versiontextsensor_id
  //   hide_timestamp: false
  version_versiontextsensor_id = new version::VersionTextSensor();
  App.register_text_sensor(version_versiontextsensor_id);
  version_versiontextsensor_id->set_name("Doorbell ESPHome Version");
  version_versiontextsensor_id->set_object_id("doorbell_esphome_version");
  version_versiontextsensor_id->set_disabled_by_default(false);
  version_versiontextsensor_id->set_icon("mdi:new-box");
  version_versiontextsensor_id->set_entity_category(::ENTITY_CATEGORY_DIAGNOSTIC);
  mqtt_mqtttextsensor_id = new mqtt::MQTTTextSensor(version_versiontextsensor_id);
  mqtt_mqtttextsensor_id->set_component_source("mqtt");
  App.register_component(mqtt_mqtttextsensor_id);
  version_versiontextsensor_id->set_component_source("version.text_sensor");
  App.register_component(version_versiontextsensor_id);
  version_versiontextsensor_id->set_hide_timestamp(false);
  // text_sensor.wifi_info:
  //   platform: wifi_info
  //   ip_address:
  //     name: Doorbell IP
  //     disabled_by_default: false
  //     mqtt_id: mqtt_mqtttextsensor_id_2
  //     id: wifi_info_ipaddresswifiinfo_id
  //     entity_category: diagnostic
  //     update_interval: 1s
  //   ssid:
  //     name: Doorbell SSID
  //     disabled_by_default: false
  //     mqtt_id: mqtt_mqtttextsensor_id_3
  //     id: wifi_info_ssidwifiinfo_id
  //     entity_category: diagnostic
  //     update_interval: 1s
  //   bssid:
  //     name: Doorbell BSSID
  //     disabled_by_default: false
  //     mqtt_id: mqtt_mqtttextsensor_id_4
  //     id: wifi_info_bssidwifiinfo_id
  //     entity_category: diagnostic
  //     update_interval: 1s
  wifi_info_ssidwifiinfo_id = new wifi_info::SSIDWiFiInfo();
  App.register_text_sensor(wifi_info_ssidwifiinfo_id);
  wifi_info_ssidwifiinfo_id->set_name("Doorbell SSID");
  wifi_info_ssidwifiinfo_id->set_object_id("doorbell_ssid");
  wifi_info_ssidwifiinfo_id->set_disabled_by_default(false);
  wifi_info_ssidwifiinfo_id->set_entity_category(::ENTITY_CATEGORY_DIAGNOSTIC);
  mqtt_mqtttextsensor_id_3 = new mqtt::MQTTTextSensor(wifi_info_ssidwifiinfo_id);
  mqtt_mqtttextsensor_id_3->set_component_source("mqtt");
  App.register_component(mqtt_mqtttextsensor_id_3);
  wifi_info_ssidwifiinfo_id->set_update_interval(1000);
  wifi_info_ssidwifiinfo_id->set_component_source("wifi_info.text_sensor");
  App.register_component(wifi_info_ssidwifiinfo_id);
  wifi_info_bssidwifiinfo_id = new wifi_info::BSSIDWiFiInfo();
  App.register_text_sensor(wifi_info_bssidwifiinfo_id);
  wifi_info_bssidwifiinfo_id->set_name("Doorbell BSSID");
  wifi_info_bssidwifiinfo_id->set_object_id("doorbell_bssid");
  wifi_info_bssidwifiinfo_id->set_disabled_by_default(false);
  wifi_info_bssidwifiinfo_id->set_entity_category(::ENTITY_CATEGORY_DIAGNOSTIC);
  mqtt_mqtttextsensor_id_4 = new mqtt::MQTTTextSensor(wifi_info_bssidwifiinfo_id);
  mqtt_mqtttextsensor_id_4->set_component_source("mqtt");
  App.register_component(mqtt_mqtttextsensor_id_4);
  wifi_info_bssidwifiinfo_id->set_update_interval(1000);
  wifi_info_bssidwifiinfo_id->set_component_source("wifi_info.text_sensor");
  App.register_component(wifi_info_bssidwifiinfo_id);
  wifi_info_ipaddresswifiinfo_id = new wifi_info::IPAddressWiFiInfo();
  App.register_text_sensor(wifi_info_ipaddresswifiinfo_id);
  wifi_info_ipaddresswifiinfo_id->set_name("Doorbell IP");
  wifi_info_ipaddresswifiinfo_id->set_object_id("doorbell_ip");
  wifi_info_ipaddresswifiinfo_id->set_disabled_by_default(false);
  wifi_info_ipaddresswifiinfo_id->set_entity_category(::ENTITY_CATEGORY_DIAGNOSTIC);
  mqtt_mqtttextsensor_id_2 = new mqtt::MQTTTextSensor(wifi_info_ipaddresswifiinfo_id);
  mqtt_mqtttextsensor_id_2->set_component_source("mqtt");
  App.register_component(mqtt_mqtttextsensor_id_2);
  wifi_info_ipaddresswifiinfo_id->set_update_interval(1000);
  wifi_info_ipaddresswifiinfo_id->set_component_source("wifi_info.text_sensor");
  App.register_component(wifi_info_ipaddresswifiinfo_id);
  // sensor.uptime:
  //   platform: uptime
  //   name: Doorbell Uptime
  //   disabled_by_default: false
  //   mqtt_id: mqtt_mqttsensorcomponent_id
  //   force_update: false
  //   id: uptime_uptimesecondssensor_id
  //   unit_of_measurement: s
  //   icon: mdi:timer-outline
  //   accuracy_decimals: 0
  //   device_class: duration
  //   state_class: total_increasing
  //   entity_category: diagnostic
  //   update_interval: 60s
  //   type: seconds
  uptime_uptimesecondssensor_id = new uptime::UptimeSecondsSensor();
  App.register_sensor(uptime_uptimesecondssensor_id);
  uptime_uptimesecondssensor_id->set_name("Doorbell Uptime");
  uptime_uptimesecondssensor_id->set_object_id("doorbell_uptime");
  uptime_uptimesecondssensor_id->set_disabled_by_default(false);
  uptime_uptimesecondssensor_id->set_icon("mdi:timer-outline");
  uptime_uptimesecondssensor_id->set_entity_category(::ENTITY_CATEGORY_DIAGNOSTIC);
  uptime_uptimesecondssensor_id->set_device_class("duration");
  uptime_uptimesecondssensor_id->set_state_class(sensor::STATE_CLASS_TOTAL_INCREASING);
  uptime_uptimesecondssensor_id->set_unit_of_measurement("s");
  uptime_uptimesecondssensor_id->set_accuracy_decimals(0);
  uptime_uptimesecondssensor_id->set_force_update(false);
  mqtt_mqttsensorcomponent_id = new mqtt::MQTTSensorComponent(uptime_uptimesecondssensor_id);
  mqtt_mqttsensorcomponent_id->set_component_source("mqtt");
  App.register_component(mqtt_mqttsensorcomponent_id);
  uptime_uptimesecondssensor_id->set_update_interval(60000);
  uptime_uptimesecondssensor_id->set_component_source("uptime.sensor");
  App.register_component(uptime_uptimesecondssensor_id);
  // sensor.wifi_signal:
  //   platform: wifi_signal
  //   name: Doorbell WiFi Signal
  //   update_interval: 60s
  //   disabled_by_default: false
  //   mqtt_id: mqtt_mqttsensorcomponent_id_2
  //   force_update: false
  //   id: wifi_signal_wifisignalsensor_id
  //   unit_of_measurement: dBm
  //   accuracy_decimals: 0
  //   device_class: signal_strength
  //   state_class: measurement
  //   entity_category: diagnostic
  wifi_signal_wifisignalsensor_id = new wifi_signal::WiFiSignalSensor();
  App.register_sensor(wifi_signal_wifisignalsensor_id);
  wifi_signal_wifisignalsensor_id->set_name("Doorbell WiFi Signal");
  wifi_signal_wifisignalsensor_id->set_object_id("doorbell_wifi_signal");
  wifi_signal_wifisignalsensor_id->set_disabled_by_default(false);
  wifi_signal_wifisignalsensor_id->set_entity_category(::ENTITY_CATEGORY_DIAGNOSTIC);
  wifi_signal_wifisignalsensor_id->set_device_class("signal_strength");
  wifi_signal_wifisignalsensor_id->set_state_class(sensor::STATE_CLASS_MEASUREMENT);
  wifi_signal_wifisignalsensor_id->set_unit_of_measurement("dBm");
  wifi_signal_wifisignalsensor_id->set_accuracy_decimals(0);
  wifi_signal_wifisignalsensor_id->set_force_update(false);
  mqtt_mqttsensorcomponent_id_2 = new mqtt::MQTTSensorComponent(wifi_signal_wifisignalsensor_id);
  mqtt_mqttsensorcomponent_id_2->set_component_source("mqtt");
  App.register_component(mqtt_mqttsensorcomponent_id_2);
  wifi_signal_wifisignalsensor_id->set_update_interval(60000);
  wifi_signal_wifisignalsensor_id->set_component_source("wifi_signal.sensor");
  App.register_component(wifi_signal_wifisignalsensor_id);
  // switch.restart:
  //   platform: restart
  //   name: Doorbell Restart
  //   disabled_by_default: false
  //   mqtt_id: mqtt_mqttswitchcomponent_id
  //   restore_mode: ALWAYS_OFF
  //   id: restart_restartswitch_id
  //   entity_category: config
  //   icon: mdi:restart
  restart_restartswitch_id = new restart::RestartSwitch();
  App.register_switch(restart_restartswitch_id);
  restart_restartswitch_id->set_name("Doorbell Restart");
  restart_restartswitch_id->set_object_id("doorbell_restart");
  restart_restartswitch_id->set_disabled_by_default(false);
  restart_restartswitch_id->set_icon("mdi:restart");
  restart_restartswitch_id->set_entity_category(::ENTITY_CATEGORY_CONFIG);
  mqtt_mqttswitchcomponent_id = new mqtt::MQTTSwitchComponent(restart_restartswitch_id);
  mqtt_mqttswitchcomponent_id->set_component_source("mqtt");
  App.register_component(mqtt_mqttswitchcomponent_id);
  restart_restartswitch_id->set_restore_mode(switch_::SWITCH_ALWAYS_OFF);
  restart_restartswitch_id->set_component_source("restart.switch");
  App.register_component(restart_restartswitch_id);
  // switch.gpio:
  //   platform: gpio
  //   id: relay
  //   inverted: true
  //   name: Doorbell Chime
  //   pin:
  //     number: 0
  //     mode:
  //       output: true
  //       input: false
  //       open_drain: false
  //       pullup: false
  //       pulldown: false
  //       analog: false
  //     id: esphome_esp8266_esp8266gpiopin_id
  //     inverted: false
  //   disabled_by_default: false
  //   mqtt_id: mqtt_mqttswitchcomponent_id_2
  //   restore_mode: ALWAYS_OFF
  //   interlock_wait_time: 0ms
  relay = new gpio::GPIOSwitch();
  App.register_switch(relay);
  relay->set_name("Doorbell Chime");
  relay->set_object_id("doorbell_chime");
  relay->set_disabled_by_default(false);
  relay->set_inverted(true);
  mqtt_mqttswitchcomponent_id_2 = new mqtt::MQTTSwitchComponent(relay);
  mqtt_mqttswitchcomponent_id_2->set_component_source("mqtt");
  App.register_component(mqtt_mqttswitchcomponent_id_2);
  relay->set_restore_mode(switch_::SWITCH_ALWAYS_OFF);
  relay->set_component_source("gpio.switch");
  App.register_component(relay);
  esphome_esp8266_esp8266gpiopin_id = new esphome::esp8266::ESP8266GPIOPin();
  esphome_esp8266_esp8266gpiopin_id->set_pin(0);
  esphome_esp8266_esp8266gpiopin_id->set_inverted(false);
  esphome_esp8266_esp8266gpiopin_id->set_flags(gpio::Flags::FLAG_OUTPUT);
  relay->set_pin(esphome_esp8266_esp8266gpiopin_id);
  // switch.template:
  //   platform: template
  //   name: Doorbell Chime Active
  //   id: chime_active
  //   restore_mode: DISABLED
  //   turn_on_action:
  //     then:
  //     - globals.set:
  //         id: chime
  //         value: 'true'
  //       type_id: globals_globalvarsetaction_id
  //     trigger_id: trigger_id
  //     automation_id: automation_id
  //   turn_off_action:
  //     then:
  //     - globals.set:
  //         id: chime
  //         value: 'false'
  //       type_id: globals_globalvarsetaction_id_2
  //     trigger_id: trigger_id_2
  //     automation_id: automation_id_2
  //   lambda: !lambda |-
  //     return id(chime);
  //   disabled_by_default: false
  //   mqtt_id: mqtt_mqttswitchcomponent_id_3
  //   optimistic: false
  //   assumed_state: false
  chime_active = new template_::TemplateSwitch();
  App.register_switch(chime_active);
  chime_active->set_name("Doorbell Chime Active");
  chime_active->set_object_id("doorbell_chime_active");
  chime_active->set_disabled_by_default(false);
  mqtt_mqttswitchcomponent_id_3 = new mqtt::MQTTSwitchComponent(chime_active);
  mqtt_mqttswitchcomponent_id_3->set_component_source("mqtt");
  App.register_component(mqtt_mqttswitchcomponent_id_3);
  chime_active->set_restore_mode(switch_::SWITCH_RESTORE_DISABLED);
  chime_active->set_component_source("template.switch");
  App.register_component(chime_active);
  // binary_sensor.gpio:
  //   platform: gpio
  //   id: button
  //   name: Doorbell Button
  //   pin:
  //     number: 2
  //     mode:
  //       input: true
  //       pullup: true
  //       output: false
  //       open_drain: false
  //       pulldown: false
  //       analog: false
  //     inverted: true
  //     id: esphome_esp8266_esp8266gpiopin_id_2
  //   filters:
  //   - delayed_on: 25ms
  //     type_id: binary_sensor_delayedonfilter_id
  //   - delayed_off: 25ms
  //     type_id: binary_sensor_delayedofffilter_id
  //   on_press:
  //   - then:
  //     - if:
  //         condition:
  //           and:
  //           - switch.is_on:
  //               id: chime_active
  //             type_id: switch__switchcondition_id
  //           type_id: andcondition_id
  //         then:
  //         - switch.turn_on:
  //             id: relay
  //           type_id: switch__turnonaction_id
  //       type_id: ifaction_id
  //     automation_id: automation_id_3
  //     trigger_id: binary_sensor_presstrigger_id
  //   on_release:
  //   - then:
  //     - switch.turn_off:
  //         id: relay
  //       type_id: switch__turnoffaction_id
  //     automation_id: automation_id_4
  //     trigger_id: binary_sensor_releasetrigger_id
  //   disabled_by_default: false
  //   mqtt_id: mqtt_mqttbinarysensorcomponent_id
  button = new gpio::GPIOBinarySensor();
  App.register_binary_sensor(button);
  button->set_name("Doorbell Button");
  button->set_object_id("doorbell_button");
  button->set_disabled_by_default(false);
  binary_sensor_delayedonfilter_id = new binary_sensor::DelayedOnFilter();
  binary_sensor_delayedonfilter_id->set_component_source("binary_sensor");
  App.register_component(binary_sensor_delayedonfilter_id);
  binary_sensor_delayedonfilter_id->set_delay(25);
  binary_sensor_delayedofffilter_id = new binary_sensor::DelayedOffFilter();
  binary_sensor_delayedofffilter_id->set_component_source("binary_sensor");
  App.register_component(binary_sensor_delayedofffilter_id);
  binary_sensor_delayedofffilter_id->set_delay(25);
  button->add_filters({binary_sensor_delayedonfilter_id, binary_sensor_delayedofffilter_id});
  binary_sensor_presstrigger_id = new binary_sensor::PressTrigger(button);
  automation_id_3 = new Automation<>(binary_sensor_presstrigger_id);
  switch__switchcondition_id = new switch_::SwitchCondition<>(chime_active, true);
  andcondition_id = new AndCondition<>({switch__switchcondition_id});
  ifaction_id = new IfAction<>(andcondition_id);
  switch__turnonaction_id = new switch_::TurnOnAction<>(relay);
  ifaction_id->add_then({switch__turnonaction_id});
  automation_id_3->add_actions({ifaction_id});
  binary_sensor_releasetrigger_id = new binary_sensor::ReleaseTrigger(button);
  automation_id_4 = new Automation<>(binary_sensor_releasetrigger_id);
  switch__turnoffaction_id = new switch_::TurnOffAction<>(relay);
  automation_id_4->add_actions({switch__turnoffaction_id});
  mqtt_mqttbinarysensorcomponent_id = new mqtt::MQTTBinarySensorComponent(button);
  mqtt_mqttbinarysensorcomponent_id->set_component_source("mqtt");
  App.register_component(mqtt_mqttbinarysensorcomponent_id);
  button->set_component_source("gpio.binary_sensor");
  App.register_component(button);
  esphome_esp8266_esp8266gpiopin_id_2 = new esphome::esp8266::ESP8266GPIOPin();
  esphome_esp8266_esp8266gpiopin_id_2->set_pin(2);
  esphome_esp8266_esp8266gpiopin_id_2->set_inverted(true);
  esphome_esp8266_esp8266gpiopin_id_2->set_flags((gpio::Flags::FLAG_INPUT | gpio::Flags::FLAG_PULLUP));
  button->set_pin(esphome_esp8266_esp8266gpiopin_id_2);
  // network:
  //   enable_ipv6: false
  //   min_ipv6_addr_count: 0
  // md5:
  // socket:
  //   implementation: lwip_tcp
  // globals:
  //   id: chime
  //   type: bool
  //   restore_value: true
  //   initial_value: 'true'
  chime = new globals::RestoringGlobalsComponent<bool>(true);
  chime->set_component_source("globals");
  App.register_component(chime);
  chime->set_name_hash(75002394);
  chime_active->set_state_lambda([=]() -> optional<bool> {
      #line 107 "doorbell.yaml"
      return chime->value();
  });
  automation_id_2 = new Automation<>(chime_active->get_turn_off_trigger());
  globals_globalvarsetaction_id_2 = new globals::GlobalVarSetAction<globals::RestoringGlobalsComponent<bool>>(chime);
  globals_globalvarsetaction_id_2->set_value(false);
  automation_id_2->add_actions({globals_globalvarsetaction_id_2});
  automation_id = new Automation<>(chime_active->get_turn_on_trigger());
  globals_globalvarsetaction_id = new globals::GlobalVarSetAction<globals::RestoringGlobalsComponent<bool>>(chime);
  globals_globalvarsetaction_id->set_value(true);
  automation_id->add_actions({globals_globalvarsetaction_id});
  chime_active->set_optimistic(false);
  chime_active->set_assumed_state(false);
  // =========== AUTO GENERATED CODE END ============
  App.setup();
}

void loop() {
  App.loop();
}
