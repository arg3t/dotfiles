#!/usr/bin/env python3

import json
import urllib.request
import os
from datetime import datetime, date
import urllib.parse

API_KEY = "YOUR_API_KEY"
CITY = "YOUR_CITY"
ENCODED_CITY = urllib.parse.quote(CITY)
CACHE_FILE = os.path.expanduser("~/.cache/eww_weather_cache.json")

FALLBACK_DATA = {
    "location": "Unknown",
    "temp": "0",
    "desc": "Unknown",
    "type": "day",
    "humidity": "0",
    "wind": "0",
    "icon": "",
    "icon_class": "weather-icon unknown",
    "forecast": [],
    "sunrise": "--:--",
    "sunset": "--:--",
}


def load_cache():
    if os.path.exists(CACHE_FILE):
        try:
            with open(CACHE_FILE, "r") as f:
                return json.load(f)
        except Exception:
            return None
    return None


def save_cache(data):
    try:
        os.makedirs(os.path.dirname(CACHE_FILE), exist_ok=True)
        with open(CACHE_FILE, "w") as f:
            json.dump(data, f)
    except Exception:
        pass


def get_weather_icon(desc, weather_type="day"):
    desc_lower = desc.lower()

    if any(x in desc_lower for x in ["clear", "sunny"]):
        return (
            "󰖔" if weather_type == "night" else "",
            "weather-icon clear-night"
            if weather_type == "night"
            else "weather-icon clear-day",
        )

    elif any(
        x in desc_lower
        for x in [
            "few clouds",
            "scattered clouds",
            "broken clouds",
            "partly cloudy",
            "scattered",
            "broken",
            "partly",
        ]
    ):
        return (
            "" if weather_type == "night" else "",
            "weather-icon cloud-night"
            if weather_type == "night"
            else "weather-icon cloud-day",
        )

    elif any(x in desc_lower for x in ["cloudy", "overcast", "clouds"]):
        return ("", "weather-icon cloudy")

    elif any(x in desc_lower for x in ["mist", "haze"]):
        return ("", "weather-icon mist")

    elif any(x in desc_lower for x in ["fog", "smoke", "dust"]):
        return (
            "" if weather_type == "night" else "",
            "weather-icon mist",
        )

    elif any(x in desc_lower for x in ["drizzle", "light rain"]):
        return ("󰖗", "weather-icon drizzle")

    elif any(x in desc_lower for x in ["shower"]):
        return (
            "" if weather_type == "night" else "",
            "weather-icon rain",
        )

    elif "thunderstorm" in desc_lower and "rain" in desc_lower:
        return (
            "" if weather_type == "night" else "",
            "weather-icon thunder",
        )

    elif "thunderstorm" in desc_lower:
        return ("󰖓", "weather-icon thunder")

    elif any(x in desc_lower for x in ["heavy snow", "blizzard"]):
        return ("", "weather-icon snow")

    elif "snow" in desc_lower:
        return ("󰖘", "weather-icon snow")

    elif any(x in desc_lower for x in ["sleet", "ice"]):
        return ("󰖒", "weather-icon snow")

    elif any(x in desc_lower for x in ["rain"]):
        return (
            "" if weather_type == "night" else "",
            "weather-icon rain",
        )

    return ("", "weather-icon unknown")


def fetch_current():
    url = f"https://api.openweathermap.org/data/2.5/weather?q={ENCODED_CITY}&units=metric&appid={API_KEY}"
    try:
        req = urllib.request.Request(
            url, headers={"User-Agent": "EwwWeatherWidget/1.0"}
        )
        with urllib.request.urlopen(req, timeout=8) as response:
            return json.loads(response.read().decode())
    except Exception:
        return None


def fetch_forecast():
    url = f"https://api.openweathermap.org/data/2.5/forecast?q={ENCODED_CITY}&units=metric&appid={API_KEY}"
    try:
        req = urllib.request.Request(
            url, headers={"User-Agent": "EwwWeatherWidget/1.0"}
        )
        with urllib.request.urlopen(req, timeout=8) as response:
            return json.loads(response.read().decode())
    except Exception:
        return None


def main():
    current_raw = fetch_current()
    forecast_raw = fetch_forecast()

    if not current_raw or not forecast_raw:
        cached = load_cache()
        if cached:
            print(json.dumps(cached))
        else:
            print(json.dumps(FALLBACK_DATA))
        return

    try:
        temp_c = str(round(current_raw["main"]["temp"]))
        humidity = str(current_raw["main"]["humidity"])
        desc = current_raw["weather"][0]["description"].title().strip()
        wind_kmh = str(round(current_raw["wind"]["speed"] * 3.6))
        current_time = current_raw.get("dt", datetime.now().timestamp())
        sunrise_ts = current_raw["sys"]["sunrise"]
        sunset_ts = current_raw["sys"]["sunset"]
        weather_type = "day" if sunrise_ts <= current_time < sunset_ts else "night"

        sunrise = datetime.fromtimestamp(sunrise_ts).strftime("%-I:%M %p")
        sunset = datetime.fromtimestamp(sunset_ts).strftime("%-I:%M %p")

        current_icon, current_class = get_weather_icon(desc, weather_type)

        # Forecast
        today = date.today()
        days = {}
        for item in forecast_raw["list"]:
            dt = datetime.fromtimestamp(item["dt"])
            date_key = dt.strftime("%Y-%m-%d")
            hour = dt.hour
            if date_key not in days or abs(hour - 12) < abs(
                datetime.fromtimestamp(days[date_key]["dt"]).hour - 12
            ):
                days[date_key] = item

        forecast_list = []
        for date_key in sorted(days.keys()):
            item = days[date_key]
            dt = datetime.fromtimestamp(item["dt"])
            if dt.date() == today:
                continue
            f_desc = item["weather"][0]["description"].title()
            f_temp = round(item["main"]["temp"], 1)

            f_icon, f_class = get_weather_icon(f_desc, "day")

            forecast_list.append(
                {
                    "day": dt.strftime("%A"),
                    "date": dt.strftime("%d %b"),
                    "temp": f_temp,
                    "desc": f_desc,
                    "icon": f_icon,
                    "icon_class": f_class,
                }
            )

        forecast_list = forecast_list[:4]

        output = {
            "location": current_raw.get("name", ""),
            "temp": temp_c,
            "desc": desc,
            "type": weather_type,
            "humidity": humidity,
            "wind": wind_kmh,
            "icon": current_icon,
            "icon_class": current_class,
            "forecast": forecast_list,
            "sunrise": sunrise,
            "sunset": sunset,
        }

        save_cache(output)
        print(json.dumps(output))

    except (KeyError, IndexError, ValueError):
        cached = load_cache()
        if cached:
            print(json.dumps(cached))
        else:
            print(json.dumps(FALLBACK_DATA))


if __name__ == "__main__":
    main()
