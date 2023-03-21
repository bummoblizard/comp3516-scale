import csv
import matplotlib.pyplot as plt
import numpy as np
import pandas as pd
import sys

csv_path = '0g_baseline/7AA27344-6799-47D3-A092-CAE987B3AFF8.csv'

# CSV file format:
# 1st row: x axis
# 2nd row: y axis
# 3rd row: z axis

# Draw a line chart showing 3 series
def plot_data():
    df = pd.read_csv(csv_path, header=None)
    x = df.iloc[0]
    y = df.iloc[1]
    z = df.iloc[2]

    time_series = np.arange(0, len(x), 1)

    fig, (ax1, ax2, ax3) = plt.subplots(3, 1, sharex=True)
    ax1.plot(time_series, x, 'r')
    ax1.set_title('x axis')
    ax2.plot(time_series, y, 'g')
    ax2.set_title('y axis')
    ax3.plot(time_series, z, 'b')
    ax3.set_title('z axis')

    fig.suptitle(csv_path)

    plt.show()
    

if __name__ == '__main__':
    plot_data()
