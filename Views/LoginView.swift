import SwiftUI

struct LoginView: View {
    @EnvironmentObject var authManager: AuthenticationManager
    @State private var email = ""
    @State private var password = ""
    @State private var isSigningUp = false
    @State private var isLoading = false
    
    var body: some View {
        NavigationView {
            ZStack {
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color(red: 0.1, green: 0.15, blue: 0.3),
                        Color(red: 0.15, green: 0.2, blue: 0.35)
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                VStack(spacing: 20) {
                    VStack(spacing: 12) {
                        Image(systemName: "heart.fill")
                            .font(.system(size: 60))
                            .foregroundColor(.appCyan)
                        
                        Text("Health Tracker")
                            .font(.system(size: 32, weight: .bold))
                            .foregroundColor(.white)
                        
                        Text("Track your health & location")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.white.opacity(0.7))
                    }
                    .padding(.top, 60)
                    .padding(.bottom, 40)
                    
                    VStack(spacing: 16) {
                        // Email Input
                        HStack(spacing: 12) {
                            Image(systemName: "envelope.fill")
                                .foregroundColor(.appCyan)
                                .frame(width: 24)
                            
                            TextField("Email", text: $email)
                                .textContentType(.emailAddress)
                                .keyboardType(.emailAddress)
                                .autocapitalization(.none)
                                .textFieldStyle(.plain)
                                .foregroundColor(.white)
                                .placeholder(when: email.isEmpty) {
                                    Text("your@email.com")
                                        .foregroundColor(.white.opacity(0.5))
                                }
                        }
                        .padding(16)
                        .background(Color.white.opacity(0.1))
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.appCyan.opacity(0.3), lineWidth: 1)
                        )
                        
                        // Password Input
                        HStack(spacing: 12) {
                            Image(systemName: "lock.fill")
                                .foregroundColor(.appCyan)
                                .frame(width: 24)
                            
                            SecureField("Password", text: $password)
                                .textContentType(.password)
                                .textFieldStyle(.plain)
                                .foregroundColor(.white)
                        }
                        .padding(16)
                        .background(Color.white.opacity(0.1))
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.appCyan.opacity(0.3), lineWidth: 1)
                        )
                    }
                    .padding(.bottom, 20)
                    
                    // Error Message
                    if let error = authManager.errorMessage {
                        Text(error)
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.red)
                            .padding(12)
                            .background(Color.red.opacity(0.1))
                            .cornerRadius(8)
                    }
                    
                    // Login/Signup Button
                    Button {
                        isLoading = true
                        Task {
                            if isSigningUp {
                                await authManager.signup(email: email, password: password)
                            } else {
                                await authManager.login(email: email, password: password)
                            }
                            isLoading = false
                        }
                    } label: {
                        HStack {
                            if isLoading {
                                ProgressView()
                                    .accentColor(.white)
                            }
                            Text(isSigningUp ? "Create Account" : "Log In")
                                .font(.system(size: 16, weight: .semibold))
                        }
                        .frame(maxWidth: .infinity)
                        .padding(16)
                        .background(
                            LinearGradient(
                                gradient: Gradient(colors: [.appCyan, .blue]),
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .foregroundColor(.white)
                        .cornerRadius(12)
                    }
                    .disabled(email.isEmpty || password.isEmpty || isLoading)
                    
                    Divider()
                        .overlay(Color.white.opacity(0.2))
                    
                    // Toggle Sign Up/Login
                    HStack(spacing: 4) {
                        Text(isSigningUp ? "Already have an account?" : "Don't have an account?")
                            .foregroundColor(.white.opacity(0.7))
                        
                        Button {
                            isSigningUp.toggle()
                            authManager.errorMessage = nil
                        } label: {
                            Text(isSigningUp ? "Log In" : "Sign Up")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.appCyan)
                        }
                    }
                    .padding(.top, 10)
                    
                    Spacer()
                    
                    // Demo Credentials
                    VStack(spacing: 8) {
                        Text("Demo Credentials")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(.white.opacity(0.5))
                        
                        HStack(spacing: 8) {
                            Button("demo@test.com") {
                                email = "demo@test.com"
                            }
                            .font(.system(size: 12))
                            .foregroundColor(.appCyan)
                            
                            Button("password123") {
                                password = "password123"
                            }
                            .font(.system(size: 12))
                            .foregroundColor(.appCyan)
                        }
                    }
                    .padding(.bottom, 40)
                }
                .padding(24)
            }
        }
    }
}

extension View {
    func placeholder<Content: View>(when shouldShow: Bool, alignment: Alignment = .leading, @ViewBuilder placeholder: () -> Content) -> some View {
        ZStack(alignment: alignment) {
            placeholder().opacity(shouldShow ? 1 : 0)
            self
        }
    }
}

struct LoginView_Previews: PreviewProvider {
    static var previews: some View {
        LoginView()
            .environmentObject(AuthenticationManager())
    }
}
