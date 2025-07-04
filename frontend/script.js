// Configuration
const CONFIG = {
    // TODO: Replace with your actual API Gateway URL
    API_GATEWAY_URL: 'https://your-api-gateway-url.amazonaws.com/prod/garden-advice',
    USER_ID: 'testUser'
};

// DOM elements
const elements = {
    getUpdateBtn: document.getElementById('getUpdateBtn'),
    loadingState: document.getElementById('loadingState'),
    resultContainer: document.getElementById('resultContainer'),
    errorContainer: document.getElementById('errorContainer'),
    retryBtn: document.getElementById('retryBtn'),
    timestamp: document.getElementById('timestamp'),
    weatherInfo: document.getElementById('weatherInfo'),
    weatherDetails: document.getElementById('weatherDetails'),
    adviceContent: document.getElementById('adviceContent'),
    errorMessage: document.getElementById('errorMessage')
};

// State management
let isLoading = false;

// Initialize the application
function init() {
    elements.getUpdateBtn.addEventListener('click', handleGetUpdate);
    elements.retryBtn.addEventListener('click', handleGetUpdate);
    
    // Check if API URL is configured
    if (CONFIG.API_GATEWAY_URL.includes('your-api-gateway-url')) {
        showError('API Gateway URL not configured. Please update the API_GATEWAY_URL in script.js');
        return;
    }
}

// Handle get update button click
async function handleGetUpdate() {
    if (isLoading) return;
    
    try {
        showLoading();
        const response = await fetchGardenUpdate();
        showResult(response);
    } catch (error) {
        console.error('Error fetching garden update:', error);
        showError(error.message || 'Failed to get garden update. Please try again.');
    }
}

// Fetch garden update from API
async function fetchGardenUpdate() {
    isLoading = true;
    
    const requestBody = {
        user_id: CONFIG.USER_ID
    };
    
    const response = await fetch(CONFIG.API_GATEWAY_URL, {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json',
        },
        body: JSON.stringify(requestBody)
    });
    
    const data = await response.json();
    
    if (!response.ok) {
        throw new Error(data.message || `HTTP ${response.status}: ${response.statusText}`);
    }
    
    return data;
}

// Show loading state
function showLoading() {
    hideAllStates();
    elements.loadingState.classList.remove('hidden');
    elements.getUpdateBtn.disabled = true;
    isLoading = true;
}

// Show result
function showResult(data) {
    hideAllStates();
    
    // Set timestamp
    if (data.timestamp) {
        const date = new Date(data.timestamp);
        elements.timestamp.textContent = formatTimestamp(date);
    }
    
    // Show weather information if available
    if (data.weather_conditions && Object.keys(data.weather_conditions).length > 0) {
        showWeatherInfo(data.weather_conditions);
    }
    
    // Show advice content
    if (data.advice) {
        showAdviceContent(data.advice);
    }
    
    elements.resultContainer.classList.remove('hidden');
    resetLoadingState();
}

// Show weather information
function showWeatherInfo(weatherConditions) {
    const weatherItems = [];
    
    if (weatherConditions.temperature !== undefined) {
        weatherItems.push(`<div class="weather-item">🌡️ ${weatherConditions.temperature}°C</div>`);
    }
    
    if (weatherConditions.humidity !== undefined) {
        weatherItems.push(`<div class="weather-item">💧 ${weatherConditions.humidity}% humidity</div>`);
    }
    
    if (weatherConditions.condition) {
        const conditionIcon = getWeatherIcon(weatherConditions.condition);
        weatherItems.push(`<div class="weather-item">${conditionIcon} ${weatherConditions.condition}</div>`);
    }
    
    if (weatherItems.length > 0) {
        elements.weatherDetails.innerHTML = weatherItems.join('');
        elements.weatherInfo.classList.remove('hidden');
    }
}

// Get weather icon based on condition
function getWeatherIcon(condition) {
    const conditionLower = condition.toLowerCase();
    
    if (conditionLower.includes('sunny') || conditionLower.includes('clear')) {
        return '☀️';
    } else if (conditionLower.includes('cloudy')) {
        return '☁️';
    } else if (conditionLower.includes('rain')) {
        return '🌧️';
    } else if (conditionLower.includes('storm')) {
        return '⛈️';
    } else if (conditionLower.includes('snow')) {
        return '❄️';
    } else if (conditionLower.includes('fog')) {
        return '🌫️';
    } else {
        return '🌤️';
    }
}

// Show advice content
function showAdviceContent(advice) {
    // Split advice into paragraphs for better readability
    const paragraphs = advice.split('\n').filter(p => p.trim().length > 0);
    const formattedAdvice = paragraphs.map(p => `<p>${p.trim()}</p>`).join('');
    
    elements.adviceContent.innerHTML = formattedAdvice;
}

// Show error state
function showError(message) {
    hideAllStates();
    elements.errorMessage.textContent = message;
    elements.errorContainer.classList.remove('hidden');
    resetLoadingState();
}

// Hide all states
function hideAllStates() {
    elements.loadingState.classList.add('hidden');
    elements.resultContainer.classList.add('hidden');
    elements.errorContainer.classList.add('hidden');
    elements.weatherInfo.classList.add('hidden');
}

// Reset loading state
function resetLoadingState() {
    elements.getUpdateBtn.disabled = false;
    isLoading = false;
}

// Format timestamp for display
function formatTimestamp(date) {
    const options = {
        year: 'numeric',
        month: 'short',
        day: 'numeric',
        hour: '2-digit',
        minute: '2-digit',
        timeZoneName: 'short'
    };
    
    return date.toLocaleDateString('en-US', options);
}

// Handle network errors and provide user-friendly messages
window.addEventListener('online', () => {
    console.log('Connection restored');
});

window.addEventListener('offline', () => {
    showError('You appear to be offline. Please check your internet connection and try again.');
});

// Initialize the application when DOM is loaded
document.addEventListener('DOMContentLoaded', init);