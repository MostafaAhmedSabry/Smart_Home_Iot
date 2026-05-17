#include <DHT.h>

#define DHTPIN 2
#define DHTTYPE DHT11
DHT dht(DHTPIN, DHTTYPE);

#define PIR 7
#define MQ2 A0
#define SOIL A1
#define RAIN 8
#define TRIG 9
#define ECHO 10

void setup() {
  Serial.begin(9600);
  dht.begin();

  pinMode(PIR, INPUT);
  pinMode(TRIG, OUTPUT);
  pinMode(ECHO, INPUT);
}

void loop() {

  float temp = dht.readTemperature();
  float hum = dht.readHumidity();

  int pir = digitalRead(PIR);
  int gas = analogRead(MQ2);
 int soil = analogRead(SOIL);
 int soilValue = analogRead(SOIL);

 soil = map(soilValue, 1023, 300, 0, 100);

soil = constrain(soil, 0, 100);

  int rain = digitalRead(RAIN);

  digitalWrite(TRIG, LOW);
  delayMicroseconds(2);
  digitalWrite(TRIG, HIGH);
  delayMicroseconds(10);
  digitalWrite(TRIG, LOW);

  long duration = pulseIn(ECHO, HIGH);
  int distance = duration * 0.034 / 2;

  Serial.print(temp); Serial.print(",");
  Serial.print(hum); Serial.print(",");
  Serial.print(gas); Serial.print(",");
  Serial.print(soil); Serial.print(",");
  Serial.print(rain); Serial.print(",");
  Serial.print(pir); Serial.print(",");
  Serial.println(distance);

  delay(1500);
}
