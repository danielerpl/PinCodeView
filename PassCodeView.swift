import SwiftUI

struct PassCodeView: View {
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        ZStack {
            
            //MARK: - Background Color
            Color.black
                .edgesIgnoringSafeArea(.all)
            
            VStack {
                //MARK: - View title
                HStack {
                    Text(
                        localizedViewTitle.uppercased()
                        
                    ).foregroundColor(.white)
                        .font(.title2)
                }
                
                //MARK: - View description
                HStack {
                    Text(
                        localizedPinDescription.uppercased()
                        
                    ).foregroundColor(.white)
                        .font(.title2)
                }.padding(.top, 50)
                
                //MARK: - Error message
                HStack {
                    Text(
                        localizedError.uppercased()
                    ).foregroundColor(.redColor)
                        .font(.callout)
                }.padding()
                
                HStack {
                    Spacer()
                    HStack(alignment: .center) {
                        //MARK: - Typing pin
                        ForEach(0..<typingPin.count, id: \.self) { index in
                            Text(self.getStringOrStar(at: index))
                                .foregroundColor(isMatching ? .white : .red)
                                .frame(height: 50)
                        }
                        
                        //To avoid no space when no string value
                        if typingPin.count == 0 {
                            Text("")
                                .frame(height: 50)
                        }
                        
                    }.frame(maxWidth: .infinity)
                    
                }.padding([.leading, .trailing])
                Spacer()
                //MARK: - Number pad
                KeyPad(string: $typingPin)
                    .environment(\.showPinAction, $showPin)
                
                Spacer()
            }
            .font(.largeTitle)
            .padding()
            
            // Handling typing change
            .onChange(of: typingPin) { newValue in
                onChangePerformer(newValue)
            }
            
            .onAppear {
                self.viewPinType = self.toCheckPin == nil ? .createPin : .verifyPin
            }
        }
    }
    
    //MARK: - Variables
    
    @State var toCheckPin: String?
    /// On change pin, and extra verify will be required
    @State var requiredVerify: Bool = false
    
    @State private var isGeneratedNewPin: Bool = false
    @State private var typingPin = ""
    @State private var showPin = false
    @State private var viewPinType: PinViewType = .verifyPin
    
    
    enum PinViewType {
        case verifyPin, createPin
    }
    
    var didMatchPin: () -> Void
    
    private func getStringOrStar(at index: Int) -> String {
        if self.showPin {
            return self.typingPin.digits[index].numberString
        }
        return "*"
    }
    
    private func onChangePerformer(_ newValue: String) {
        switch viewPinType {
        case .verifyPin:
            if typingPin.count == AppConfig.pinCodeDigits, typingPin == toCheckPin {
                didMatchPin()
            }
            
        case .createPin:
            if typingPin.count == AppConfig.pinCodeDigits {
                if isGeneratedNewPin == false {
                    self.toCheckPin = typingPin
                    self.isGeneratedNewPin = true
                    self.typingPin = ""
                }else {
                    if self.toCheckPin == newValue {
                        self.typingPin = ""
                        
                        KeyChainHelper.standard.save(self.toCheckPin, service: .AppPinCode)
                        
                        if requiredVerify {
                            self.viewPinType = .verifyPin
                        }else {
                            didMatchPin()
                            dismiss()
                        }
                    }
                    
                }
            }
            
        }
    }
    
    private var isMatching: Bool {
        return  typingPin.count < AppConfig.pinCodeDigits ? true :
        typingPin.count == AppConfig.pinCodeDigits && typingPin == toCheckPin
    }
    
    private var localizedViewTitle: String {
        switch viewPinType {
        case .createPin: return String(localized: "create_pin_nav_title")
        case .verifyPin: return String(localized: "pin_nav_title")
        }
    }
    
    private var localizedPinDescription: String {
        switch viewPinType {
        case .createPin: return isGeneratedNewPin ? String(localized: "create_pin_confirm_label") : String(localized: "create_pin_create_label")
        case .verifyPin: return String(localized: "pin_description_title")
        }
    }
    
    private var localizedError: String {
        return isMatching ? "" : isGeneratedNewPin ? String(localized: "pin_missmatching_messages") : String(localized: "pin_wrong_alert_title")
    }
    
}

internal extension Int {
    
    var numberString: String {
        
        guard self < 10 else { return "0" }
        
        return String(self)
    }
}

struct KeyPadButton: View {
    var key: String
    
    var body: some View {
        Button(action: { self.action(self.key) }) {
            Color.clear
                .overlay(Circle()
                    .stroke(self.key == "⌫" ? .clear : Color.white))
                .overlay(Text(key).foregroundColor(.white))
        }.frame(width: 80, height: 80)
            .padding(10)
    }
    
    enum ActionKey: EnvironmentKey {
        static var defaultValue: (String) -> Void { { _ in } }
    }
    
    @Environment(\.keyPadButtonAction) var action: (String) -> Void
}

struct EyePadButton: View {
    
    var body: some View {
        Button {
            self.showPin.wrappedValue.toggle()
        } label: {
            Image(systemName: self.showPin.wrappedValue ? "eye" : "eye.slash")
                .foregroundColor(.white)
            
        }
        .frame(width: 80, height: 80)
        .padding(10)
    }
    
    enum ActionKey: EnvironmentKey {
        static var defaultValue: Binding<Bool> = .constant(false)
    }
    
    @Environment(\.showPinAction) var showPin: Binding<Bool>
    
    func showPin(_ showPin: Binding<Bool>) -> some View {
        environment(\.showPinAction, showPin)
    }
}

extension EnvironmentValues {
    var keyPadButtonAction: (String) -> Void {
        get { self[KeyPadButton.ActionKey.self] }
        set { self[KeyPadButton.ActionKey.self] = newValue }
    }
    
    var showPinAction: Binding<Bool> {
        get { self[EyePadButton.ActionKey.self] }
        set { self[EyePadButton.ActionKey.self] = newValue }
    }
}



struct KeyPadRow: View {
    @Environment(\.showPinAction) var showPin: Binding<Bool>
    var keys: [String]
    
    var body: some View {
        HStack {
            ForEach(keys, id: \.self) { key in
                if key == "eye" {
                    EyePadButton()
                        .environment(\.showPinAction, showPin)
                }
                else if key.isEmpty {
                    Spacer()
                }else {
                    KeyPadButton(key: key)
                }
            }
        }
    }
}

struct KeyPad: View {
    @Environment(\.showPinAction) var showPin: Binding<Bool>
    @Binding var string: String
    
    var body: some View {
        VStack {
            KeyPadRow(keys: ["1", "2", "3"])
            KeyPadRow(keys: ["4", "5", "6"])
            KeyPadRow(keys: ["7", "8", "9"])
            KeyPadRow(keys: ["eye", "0", "⌫"])
        }.environment(\.keyPadButtonAction, self.keyWasPressed(_:))
            .environment(\.showPinAction, showPin)
    }
    
    private func keyWasPressed(_ key: String) {
        switch key {
        case "⌫":
            if !string.isEmpty {
                string.removeLast()
            }
            if string.isEmpty { string = "" }
        case _ where string == "": string = key
        case _ where string.count == AppConfig.pinCodeDigits : break
        default: string += key
        }
    }
}

//MARK: - Previews
#if DEBUG
struct PassCodeView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            PassCodeView(toCheckPin: "123456", didMatchPin: {})
                .previewDisplayName("Verify PassCode")
            
            PassCodeView(toCheckPin: nil, didMatchPin: {})
                .previewDisplayName("Generate PassCode")
        }
    }
}


struct KeyPadButton_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            Color.black
                .edgesIgnoringSafeArea(.all)
            KeyPadButton(key: "8")
                .padding()
                .frame(width: 80, height: 80)
                .previewLayout(.sizeThatFits)
        }
        
        .previewDisplayName("Keypad Button")
    }
}
#endif
