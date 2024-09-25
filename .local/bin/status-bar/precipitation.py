#!/bin/python

# https://gadgets.buienradar.nl/data/raintext/?lat=52.01&lon=4.36

import sys
import math
import requests
import os

CHARS = ["▁", "▂", "▃", "▄", "▅", "▆", "▇"]


def normalize(val, low, high):
    return (val - low) / (high - low)


def clamp(val, low, high):
    return max(low, min(high, val))


def main():
    chart_length = sys.argv[1]

    # Get two environs: LATIUTUDE and LONGITUDE
    latitude = os.environ.get("LATITUDE")
    longitude = os.environ.get("LONGITUDE")

    response = requests.get(
        f"https://gadgets.buienradar.nl/data/raintext/?lat={latitude}&lon={longitude}"
    )

    # Read data from stdin
    data = [int(x.split("|")[0]) for x in response.text.strip(" \n\t\r").split("\n")]

    if sum(data) == 0:
        return

    chart_length = min(len(data), int(chart_length))
    step_size = math.ceil(len(data) / chart_length)

    i = 0

    chart = ""
    while i < len(data):
        s = sum([data[x] for x in range(i, i + step_size)]) / step_size

        i += step_size

        if i + step_size >= len(data):
            step_size = len(data) - i

        chart += CHARS[
            clamp(
                math.floor(normalize(s, 0, 255) * (len(CHARS))),
                0,
                len(CHARS) - 1,
            )
        ]

    print(chart, end="")


if __name__ == "__main__":
    main()
