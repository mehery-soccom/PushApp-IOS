import SwiftUI
import PushApp_IOS

struct ContentView: View {
    var body: some View {
        NavigationView {
            ScreenOne()
        }
        .onAppear {
            PushApp.shared.initialize(identifier: "demo$d7b9733c4d6b_1752491727304")
            PushApp.shared.login(userId: "xyz")
            PushApp.shared.sendEvent(eventName: "EVENT_LOGIN_SUCCESS", eventData: ["user_name": "xyz"])
        }
    }
}

struct ScreenOne: View {
    var body: some View {
        VStack {
            Text("Screen One")
                .font(.largeTitle)
                .padding()

            NavigationLink(destination: ScreenTwo()) {
                Text("Go to Screen Two")
                    .font(.title2)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
        }
        .navigationTitle("One")
        .trackPage(name: "ScreenOne")
    }
}

struct ScreenTwo: View {
    var body: some View {
        VStack {
            Text("Screen Two")
                .font(.largeTitle)
                .padding()

            NavigationLink(destination: ScreenThree()) {
                Text("Go to Screen Three")
                    .font(.title2)
                    .padding()
                    .background(Color.green)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
        }
        .navigationTitle("Two")
        .trackPage(name: "ScreenTwo")
    }
}

struct ScreenThree: View {
    @Environment(\.dismiss) var dismiss

    var body: some View {
        VStack {
            Text("Screen Three")
                .font(.largeTitle)
                .padding()

            Button(action: {
                dismissToRoot()
            }) {
                Text("Back to Screen One")
                    .font(.title2)
                    .padding()
                    .background(Color.red)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
        }
        .navigationTitle("Three")
        .trackPage(name: "ScreenThree")
    }

    private func dismissToRoot() {
        DispatchQueue.main.async {
            UIApplication.shared.windows.first?.rootViewController?.dismiss(animated: true, completion: nil)
        }
    }
}
