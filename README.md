# Athan Automation

Automate the Islamic call to prayer (Athan) on your Google Home/Nest devices using Shell scripts and Cron.

This project fetches daily prayer times for a specific location and dynamically schedules the Athan to play on a designated Google Home device, handling volume adjustments and restoration automatically.

## Features

- **Daily Scheduling**: Automatically updates your crontab daily with the latest prayer times.
- **Google Home Integration**: Uses `catt` (Cast All The Things) to cast the Athan audio directly to your smart speakers.
- **Smart Volume Control**: 
  - Sets a custom volume for the Athan (e.g., louder for Fajr).
  - Automatically captures and restores the original volume after the Athan finishes.
- **Robust Error Handling**: Includes retry logic for device discovery and casting commands.
- **Logging**: Maintains a detailed log of all scheduled and executed Athan sessions.

## Prerequisites

Before setting up, ensure you have the following installed on your Linux system (e.g., Raspberry Pi, Ubuntu):

- `curl`: For API requests.
- `jq`: For parsing JSON prayer times.
- `catt`: For casting to Google Home. Install via pip: `pip install catt`.
- `cron`: To handle the automation schedule.

## Files

- `athan-scheduler.sh`: The main coordinator. It fetches prayer times from the API and updates your crontab.
- `play-athan.sh`: The execution script. It handles the volume logic and casts the audio to your device.

## Setup & Installation

1. **Clone the repository**:
   ```bash
   git clone https://github.com/rbous/athan-automation.git
   cd athan-automation
   ```

2. **Configure your device**:
   Open `play-athan.sh` and update the following variables with your Google Home details:
   - `GOOGLE_HOME_NAME`: The name of your device in the Google Home app (e.g., "Home mini").
   - `GOOGLE_HOME_IP`: The static IP address of your device (highly recommended for stability).

3. **Configure the API**:
   Open `athan-scheduler.sh` and update the `API_URL` to match your location's prayer times endpoint.

4. **Make scripts executable**:
   ```bash
   chmod +x athan-scheduler.sh play-athan.sh
   ```

5. **Initial Run**:
   Run the scheduler manually to verify it fetches times and updates your crontab:
   ```bash
   ./athan-scheduler.sh
   ```

6. **Automate the Scheduler**:
   Add the scheduler to your crontab so it runs once every night (e.g., at 1:00 AM) to update the day's prayer times:
   ```bash
   crontab -e
   ```
   Add the following line:
   ```cron
   0 1 * * * /home/yourusername/athan-automation/athan-scheduler.sh
   ```

## Configuration Options

In `play-athan.sh`, you can adjust the following:
- `FAJR_VOLUME`: Volume level (0-100) for the morning prayer (default: 70).
- `OTHER_VOLUME`: Volume level for all other prayers (default: 40).
- `RETRY_DELAY`: Seconds to wait before retrying a failed connection.

## Logs

You can monitor the automation by checking the log file:
```bash
tail -f ~/athan-automation/athan.log
```

## Disclaimer

This project is intended for personal use. Ensure your audio URLs are valid and accessible by your Google Home device.
