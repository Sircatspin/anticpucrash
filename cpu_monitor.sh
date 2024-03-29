#!/bin/bash

# Set the CPU usage threshold (in percentage)
threshold=75
script_name="cpu_monitor.sh"
install_directory="/usr/local/bin"
service_file="/etc/systemd/system/cpu_monitor.service"

# Function to convert line endings
convert_line_endings() {
    tr -d '\r' | sed 's/$/\r/'
}

# Function to create the systemd service file
create_service_file() {
    cat > "$service_file" <<EOF
[Unit]
Description=CPU Monitor

[Service]
Type=simple
Restart=always
User=root
ExecStart=$install_directory/$script_name

[Install]
WantedBy=multi-user.target
EOF
}

# Function to update the script
update_script() {
    /usr/bin/curl -s https://raw.githubusercontent.com/Sircatspin/anticpucrash/main/inst.sh | sudo bash
}

# Function to add custom message to ~/.bashrc
add_custom_message() {
    local message
    message='echo "Hosted At basmenthost.net free hosting"'
    
    # Add custom message to ~/.bashrc
    echo "$message" >> ~/.bashrc
}

# Check for updates
if [ "$1" == "update" ]; then
    update_script
    exit 0
fi

# Add custom message to ~/.bashrc
add_custom_message

# Rest of the script remains unchanged
while true; do
    total_cpu_usage=$(top -b -n 1 | awk 'NR>7 { sum += $9; } END { print sum; }')

    if [ "$total_cpu_usage" -gt "$threshold" ]; then
        echo "High total CPU usage detected ($total_cpu_usage%). Stopping processes."

        high_cpu_pids=$(top -b -n 1 | awk -v threshold="$threshold" 'NR>7 && $9 > threshold { print $1; }')

        for pid in $high_cpu_pids; do
            echo "Stopping process with PID: $pid"
            kill -9 "$pid"
        done

        echo "Processes stopped."
    fi

    sleep 5
done

echo "CPU Monitor script installed successfully."

# Make the script executable
sudo chmod +x "$install_directory/$script_name"

# Create the systemd service file
create_service_file

# Enable and start the systemd service
sudo systemctl daemon-reload
sudo systemctl enable cpu_monitor
sudo systemctl start cpu_monitor
