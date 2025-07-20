// Shared networking utilities for backend integration
const fetch = require('node-fetch');
const ConsoleUtils = require('./console-utils');

class NetworkUtils {
    constructor(baseURL = 'http://localhost:8080') {
        this.baseURL = baseURL;
        this.timeout = 5000;
    }
    
    async healthCheck() {
        try {
            ConsoleUtils.progress('Checking backend health');
            const response = await this.get('/health');
            ConsoleUtils.clearProgress();
            
            if (response.status === 'healthy') {
                ConsoleUtils.success('Backend is healthy');
                return true;
            } else {
                ConsoleUtils.warning('Backend health check failed');
                return false;
            }
        } catch (error) {
            ConsoleUtils.clearProgress();
            ConsoleUtils.error(`Backend health check failed: ${error.message}`);
            return false;
        }
    }
    
    async get(endpoint) {
        return this.request('GET', endpoint);
    }
    
    async post(endpoint, data) {
        return this.request('POST', endpoint, data);
    }
    
    async put(endpoint, data) {
        return this.request('PUT', endpoint, data);
    }
    
    async delete(endpoint) {
        return this.request('DELETE', endpoint);
    }
    
    async request(method, endpoint, data = null) {
        const url = `${this.baseURL}${endpoint}`;
        
        const options = {
            method,
            headers: {
                'Content-Type': 'application/json',
                'Accept': 'application/json'
            },
            timeout: this.timeout
        };
        
        if (data) {
            options.body = JSON.stringify(data);
        }
        
        try {
            const response = await fetch(url, options);
            
            if (!response.ok) {
                throw new Error(`HTTP ${response.status}: ${response.statusText}`);
            }
            
            const contentType = response.headers.get('content-type');
            if (contentType && contentType.includes('application/json')) {
                return await response.json();
            } else {
                return await response.text();
            }
        } catch (error) {
            if (error.name === 'AbortError') {
                throw new Error(`Request timeout after ${this.timeout}ms`);
            }
            throw error;
        }
    }
    
    async checkServices() {
        const services = [
            { name: 'API Gateway', endpoint: '/health' },
            { name: 'Auth Service', endpoint: '/auth/health' },
            { name: 'App Catalog', endpoint: '/apps/health' },
            { name: 'VM Orchestrator', endpoint: '/vm/health' }
        ];
        
        ConsoleUtils.section('Checking Backend Services');
        
        const results = {};
        
        for (const service of services) {
            try {
                await this.get(service.endpoint);
                results[service.name] = 'healthy';
                ConsoleUtils.success(`${service.name}: Online`);
            } catch (error) {
                results[service.name] = 'unhealthy';
                ConsoleUtils.error(`${service.name}: ${error.message}`);
            }
        }
        
        return results;
    }
    
    async waitForBackend(maxAttempts = 10, interval = 2000) {
        ConsoleUtils.section('Waiting for backend to be ready');
        
        for (let attempt = 1; attempt <= maxAttempts; attempt++) {
            if (await this.healthCheck()) {
                return true;
            }
            
            if (attempt < maxAttempts) {
                ConsoleUtils.info(`Attempt ${attempt}/${maxAttempts} failed, retrying in ${interval/1000}s...`);
                await new Promise(resolve => setTimeout(resolve, interval));
            }
        }
        
        ConsoleUtils.error(`Backend not ready after ${maxAttempts} attempts`);
        return false;
    }
    
    // Generate Swift networking code
    static generateNetworkServiceCode() {
        return `
// MARK: - Network Service

class NetworkService: ObservableObject {
    static let shared = NetworkService()
    
    private let baseURL = "http://localhost:8080"
    private let session = URLSession.shared
    
    private init() {}
    
    func request<T: Codable>(
        endpoint: String,
        method: HTTPMethod = .GET,
        body: Data? = nil
    ) -> AnyPublisher<T, Error> {
        guard let url = URL(string: baseURL + endpoint) else {
            return Fail(error: NetworkError.invalidURL)
                .eraseToAnyPublisher()
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = method.rawValue
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        
        if let body = body {
            request.httpBody = body
        }
        
        return session.dataTaskPublisher(for: request)
            .tryMap { data, response in
                guard let httpResponse = response as? HTTPURLResponse,
                      200...299 ~= httpResponse.statusCode else {
                    throw NetworkError.serverError
                }
                return data
            }
            .decode(type: T.self, decoder: JSONDecoder())
            .receive(on: DispatchQueue.main)
            .eraseToAnyPublisher()
    }
}

enum HTTPMethod: String {
    case GET = "GET"
    case POST = "POST"
    case PUT = "PUT"
    case DELETE = "DELETE"
}

enum NetworkError: LocalizedError {
    case invalidURL
    case serverError
    case decodingError
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid URL"
        case .serverError:
            return "Server error"
        case .decodingError:
            return "Failed to decode response"
        }
    }
}
`;
    }
}

module.exports = NetworkUtils;
