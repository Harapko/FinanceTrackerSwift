import SwiftUI

// MARK: - Category Icon Model for Swift UI Picker
struct CategoryIconItem: Identifiable, Hashable {
    let id: String
    let name: String
    let symbol: String
    let category: String
    let keywords: [String]
}

struct AddCategoryView: View {
    @Environment(\.dismiss) private var dismiss
    var initialType: CategoryTypeOption = .expense
    var onSuccess: (CategoryResponse) -> Void = { _ in }

    @State private var name: String = ""
    @State private var type: CategoryTypeOption = .expense
    @State private var selectedIcon: String = "ShoppingBag"
    @State private var selectedColorHex: String = "818cf8"
    @State private var customColor: Color = Color(hex: "818cf8")
    @State private var hexInput: String = "818cf8"
    @State private var searchText: String = ""
    @State private var selectedCategoryFilter: String = "all"
    @State private var isLoading: Bool = false
    @State private var errorMessage: String?

    // 20 Preset Curated Modern Colors
    let colorOptions: [String] = [
        "f43f5e", // Rose
        "ef4444", // Red
        "f97316", // Orange
        "f59e0b", // Amber
        "eab308", // Yellow
        "84cc16", // Lime
        "10b981", // Emerald
        "14b8a6", // Teal
        "06b6d4", // Cyan
        "0ea5e9", // Sky
        "3b82f6", // Blue
        "6366f1", // Indigo
        "8b5cf6", // Violet
        "a855f7", // Purple
        "d946ef", // Fuchsia
        "ec4899", // Pink
        "f472b6", // Light Pink
        "64748b", // Slate
        "78716c", // Stone
        "71717a"  // Zinc
    ]

    let filterCategories: [(id: String, title: String)] = [
        ("all", "All"),
        ("food", "Food"),
        ("shopping", "Shopping"),
        ("transport", "Transport"),
        ("housing", "Housing"),
        ("health", "Health"),
        ("fun", "Fun"),
        ("work", "Work"),
        ("finance", "Finance"),
        ("life", "Life"),
        ("tools", "Tools")
    ]

    let allIcons: [CategoryIconItem] = [
        // Food & Dining
        CategoryIconItem(id: "Utensils", name: "Utensils", symbol: "fork.knife", category: "food", keywords: ["food", "dining", "restaurant", "meal", "lunch", "dinner"]),
        CategoryIconItem(id: "UtensilsCrossed", name: "Cutlery", symbol: "fork.knife.circle.fill", category: "food", keywords: ["restaurant", "cutlery", "food", "eating"]),
        CategoryIconItem(id: "Coffee", name: "Coffee", symbol: "cup.and.saucer.fill", category: "food", keywords: ["coffee", "cafe", "tea", "drink", "beverage", "starbucks"]),
        CategoryIconItem(id: "Pizza", name: "Pizza", symbol: "takeoutbag.and.cup.and.straw.fill", category: "food", keywords: ["pizza", "fastfood", "junk food", "takeout", "delivery"]),
        CategoryIconItem(id: "Beer", name: "Beer", symbol: "mug.fill", category: "food", keywords: ["beer", "bar", "alcohol", "pub", "party"]),
        CategoryIconItem(id: "Wine", name: "Wine", symbol: "wineglass.fill", category: "food", keywords: ["wine", "drink", "alcohol", "bar", "celebration"]),
        CategoryIconItem(id: "Apple", name: "Apple", symbol: "apple.logo", category: "food", keywords: ["apple", "fruit", "healthy", "groceries", "snack"]),
        CategoryIconItem(id: "Cake", name: "Cake", symbol: "birthday.cake.fill", category: "food", keywords: ["cake", "dessert", "bakery", "birthday", "sweet"]),
        CategoryIconItem(id: "Cookie", name: "Cookie", symbol: "circle.hexagongrid.fill", category: "food", keywords: ["cookie", "biscuit", "snack", "sweet"]),
        CategoryIconItem(id: "Fish", name: "Fish", symbol: "fish.fill", category: "food", keywords: ["fish", "seafood", "food", "meat"]),
        CategoryIconItem(id: "Soup", name: "Soup", symbol: "cup.and.saucer.fill", category: "food", keywords: ["soup", "warm food", "ramen", "noodles", "lunch"]),

        // Shopping & Retail
        CategoryIconItem(id: "ShoppingBag", name: "Shopping Bag", symbol: "bag.fill", category: "shopping", keywords: ["shopping", "bag", "clothes", "store", "mall", "retail"]),
        CategoryIconItem(id: "ShoppingCart", name: "Cart", symbol: "cart.fill", category: "shopping", keywords: ["cart", "groceries", "supermarket", "market", "buy"]),
        CategoryIconItem(id: "Store", name: "Store", symbol: "storefront.fill", category: "shopping", keywords: ["store", "shop", "market", "boutique", "retail"]),
        CategoryIconItem(id: "Tag", name: "Tag", symbol: "tag.fill", category: "shopping", keywords: ["tag", "discount", "sale", "label", "price"]),
        CategoryIconItem(id: "Gift", name: "Gift", symbol: "gift.fill", category: "shopping", keywords: ["gift", "present", "birthday", "holiday", "donation"]),
        CategoryIconItem(id: "Package", name: "Package", symbol: "shippingbox.fill", category: "shopping", keywords: ["package", "parcel", "delivery", "amazon", "shipping", "box"]),
        CategoryIconItem(id: "Shirt", name: "Clothing", symbol: "tshirt.fill", category: "shopping", keywords: ["shirt", "clothing", "apparel", "fashion", "clothes", "wear"]),
        CategoryIconItem(id: "Watch", name: "Watch", symbol: "applewatch", category: "shopping", keywords: ["watch", "accessory", "jewelry", "clock", "time"]),
        CategoryIconItem(id: "Glasses", name: "Glasses", symbol: "eyeglasses", category: "shopping", keywords: ["glasses", "optics", "sunglasses", "vision", "eyewear"]),
        CategoryIconItem(id: "Footprints", name: "Shoes", symbol: "shoeprints.fill", category: "shopping", keywords: ["shoes", "footwear", "boots", "sneakers", "steps"]),
        CategoryIconItem(id: "CreditCard", name: "Credit Card", symbol: "creditcard.fill", category: "shopping", keywords: ["card", "payment", "credit", "debit", "subscription"]),

        // Transport & Travel
        CategoryIconItem(id: "Car", name: "Car", symbol: "car.fill", category: "transport", keywords: ["car", "vehicle", "auto", "drive", "parking", "uber", "taxi"]),
        CategoryIconItem(id: "Fuel", name: "Fuel", symbol: "fuelpump.fill", category: "transport", keywords: ["fuel", "gas", "gasoline", "petrol", "diesel", "charge"]),
        CategoryIconItem(id: "Bus", name: "Bus", symbol: "bus.fill", category: "transport", keywords: ["bus", "public transport", "transit", "commute"]),
        CategoryIconItem(id: "Plane", name: "Flight", symbol: "airplane", category: "transport", keywords: ["plane", "flight", "travel", "trip", "vacation", "airline"]),
        CategoryIconItem(id: "Train", name: "Train", symbol: "tram.fill", category: "transport", keywords: ["train", "rail", "metro", "subway", "transit"]),
        CategoryIconItem(id: "Bike", name: "Bicycle", symbol: "bicycle", category: "transport", keywords: ["bike", "bicycle", "cycling", "ride"]),
        CategoryIconItem(id: "Ship", name: "Ship", symbol: "ferry.fill", category: "transport", keywords: ["ship", "boat", "ferry", "cruise", "sea"]),
        CategoryIconItem(id: "MapPin", name: "Location", symbol: "mappin.and.ellipse", category: "transport", keywords: ["location", "place", "travel", "pin", "gps"]),
        CategoryIconItem(id: "Navigation", name: "Navigation", symbol: "location.fill", category: "transport", keywords: ["navigation", "gps", "direction", "travel", "maps"]),
        CategoryIconItem(id: "Luggage", name: "Luggage", symbol: "suitcase.fill", category: "transport", keywords: ["luggage", "baggage", "travel", "suitcase", "trip"]),
        CategoryIconItem(id: "Ticket", name: "Ticket", symbol: "ticket.fill", category: "transport", keywords: ["ticket", "event", "concert", "cinema", "transport", "pass"]),
        CategoryIconItem(id: "Compass", name: "Compass", symbol: "safari.fill", category: "transport", keywords: ["compass", "explore", "adventure", "travel", "direction"]),

        // Housing & Living
        CategoryIconItem(id: "Home", name: "Home", symbol: "house.fill", category: "housing", keywords: ["home", "house", "rent", "mortgage", "apartment", "property"]),
        CategoryIconItem(id: "Building", name: "Building", symbol: "building.fill", category: "housing", keywords: ["building", "office", "flat", "apartment", "condo"]),
        CategoryIconItem(id: "Building2", name: "Real Estate", symbol: "building.2.fill", category: "housing", keywords: ["building", "city", "real estate", "hotel"]),
        CategoryIconItem(id: "Zap", name: "Electricity", symbol: "bolt.fill", category: "housing", keywords: ["electricity", "power", "energy", "utility", "electric", "bill"]),
        CategoryIconItem(id: "Droplets", name: "Water", symbol: "drop.fill", category: "housing", keywords: ["water", "utilities", "droplet", "plumbing", "bill"]),
        CategoryIconItem(id: "Flame", name: "Heating / Gas", symbol: "flame.fill", category: "housing", keywords: ["gas", "heating", "fire", "utilities", "warmth"]),
        CategoryIconItem(id: "Wifi", name: "Internet", symbol: "wifi", category: "housing", keywords: ["wifi", "internet", "broadband", "network", "provider"]),
        CategoryIconItem(id: "Tv", name: "TV", symbol: "tv.fill", category: "housing", keywords: ["tv", "television", "cable", "entertainment", "screen"]),
        CategoryIconItem(id: "Trash2", name: "Waste", symbol: "trash.fill", category: "housing", keywords: ["trash", "waste", "garbage", "cleaning", "service"]),
        CategoryIconItem(id: "Key", name: "Key", symbol: "key.fill", category: "housing", keywords: ["key", "rent", "lock", "access", "security", "home"]),
        CategoryIconItem(id: "Lightbulb", name: "Lighting", symbol: "lightbulb.fill", category: "housing", keywords: ["light", "bulb", "idea", "electricity", "lamp"]),
        CategoryIconItem(id: "Bed", name: "Furniture / Bed", symbol: "bed.double.fill", category: "housing", keywords: ["bed", "hotel", "accommodation", "sleep", "furniture"]),
        CategoryIconItem(id: "Bath", name: "Bath / Hygiene", symbol: "shower.fill", category: "housing", keywords: ["bath", "bathroom", "hygiene", "hotel", "home"]),

        // Health & Fitness
        CategoryIconItem(id: "Heart", name: "Health", symbol: "heart.fill", category: "health", keywords: ["heart", "love", "health", "wellness", "life", "donation"]),
        CategoryIconItem(id: "HeartPulse", name: "Cardio", symbol: "heart.text.square.fill", category: "health", keywords: ["pulse", "cardio", "health", "medicine", "hospital"]),
        CategoryIconItem(id: "Activity", name: "Activity", symbol: "waveform.path.ecg", category: "health", keywords: ["activity", "fitness", "tracking", "health", "sport"]),
        CategoryIconItem(id: "Dumbbell", name: "Gym", symbol: "dumbbell.fill", category: "health", keywords: ["gym", "fitness", "workout", "exercise", "training", "sport"]),
        CategoryIconItem(id: "Pill", name: "Pharmacy", symbol: "pills.fill", category: "health", keywords: ["pill", "pharmacy", "medicine", "drugs", "treatment", "doctor"]),
        CategoryIconItem(id: "Stethoscope", name: "Doctor", symbol: "stethoscope", category: "health", keywords: ["doctor", "medical", "clinic", "hospital", "checkup"]),
        CategoryIconItem(id: "Crosshair", name: "Target", symbol: "target", category: "health", keywords: ["target", "focus", "goal", "health"]),
        CategoryIconItem(id: "Shield", name: "Insurance", symbol: "shield.fill", category: "health", keywords: ["insurance", "protection", "shield", "security", "safety"]),
        CategoryIconItem(id: "Smile", name: "Wellness", symbol: "face.smiling.inverse", category: "health", keywords: ["smile", "happy", "mental health", "therapy", "beauty"]),
        CategoryIconItem(id: "Hospital", name: "Hospital", symbol: "cross.case.fill", category: "health", keywords: ["hospital", "clinic", "emergency", "healthcare", "care"]),

        // Entertainment & Fun
        CategoryIconItem(id: "Film", name: "Movies", symbol: "film.fill", category: "fun", keywords: ["film", "movie", "cinema", "netflix", "stream", "video"]),
        CategoryIconItem(id: "Music", name: "Music", symbol: "music.note", category: "fun", keywords: ["music", "song", "spotify", "audio", "concert", "sound"]),
        CategoryIconItem(id: "Gamepad2", name: "Gaming", symbol: "gamecontroller.fill", category: "fun", keywords: ["game", "gaming", "steam", "playstation", "xbox", "console"]),
        CategoryIconItem(id: "Tv2", name: "Streaming", symbol: "play.tv.fill", category: "fun", keywords: ["tv", "shows", "streaming", "media", "series"]),
        CategoryIconItem(id: "BookOpen", name: "Reading", symbol: "book.closed.fill", category: "fun", keywords: ["book", "reading", "novel", "literature", "library"]),
        CategoryIconItem(id: "Camera", name: "Photography", symbol: "camera.fill", category: "fun", keywords: ["camera", "photo", "photography", "pictures", "media"]),
        CategoryIconItem(id: "Headphones", name: "Audio", symbol: "headphones", category: "fun", keywords: ["headphones", "music", "podcast", "audio", "listening"]),
        CategoryIconItem(id: "Palette", name: "Art & Hobby", symbol: "paintpalette.fill", category: "fun", keywords: ["art", "palette", "painting", "creative", "design", "hobby"]),
        CategoryIconItem(id: "PartyPopper", name: "Party", symbol: "party.popper.fill", category: "fun", keywords: ["party", "celebration", "birthday", "event", "festivity"]),
        CategoryIconItem(id: "Radio", name: "Podcast", symbol: "radio.fill", category: "fun", keywords: ["radio", "broadcast", "audio", "podcast", "news"]),
        CategoryIconItem(id: "Mic", name: "Microphone", symbol: "mic.fill", category: "fun", keywords: ["microphone", "podcast", "voice", "singing", "karaoke"]),

        // Work, Tech & Education
        CategoryIconItem(id: "Briefcase", name: "Job & Work", symbol: "briefcase.fill", category: "work", keywords: ["work", "job", "business", "office", "career", "freelance"]),
        CategoryIconItem(id: "GraduationCap", name: "Education", symbol: "graduationcap.fill", category: "work", keywords: ["education", "university", "college", "course", "school", "study"]),
        CategoryIconItem(id: "Laptop", name: "Laptop", symbol: "laptopcomputer", category: "work", keywords: ["laptop", "computer", "tech", "hardware", "work", "code"]),
        CategoryIconItem(id: "Smartphone", name: "Smartphone", symbol: "iphone", category: "work", keywords: ["phone", "mobile", "cell", "telecom", "carrier", "gadget"]),
        CategoryIconItem(id: "Monitor", name: "Display", symbol: "display", category: "work", keywords: ["monitor", "screen", "display", "desktop", "setup"]),
        CategoryIconItem(id: "Tablet", name: "Tablet", symbol: "ipad", category: "work", keywords: ["tablet", "ipad", "gadget", "device"]),
        CategoryIconItem(id: "Book", name: "Courseware", symbol: "book.fill", category: "work", keywords: ["book", "study", "manual", "textbook", "learning"]),
        CategoryIconItem(id: "Award", name: "Certificate", symbol: "rosette", category: "work", keywords: ["award", "certificate", "achievement", "prize", "success"]),
        CategoryIconItem(id: "Scale", name: "Legal", symbol: "scalemass.fill", category: "work", keywords: ["legal", "lawyer", "justice", "court", "counsel"]),
        CategoryIconItem(id: "FileText", name: "Documents", symbol: "doc.text.fill", category: "work", keywords: ["document", "invoice", "contract", "paperwork", "tax"]),
        CategoryIconItem(id: "Printer", name: "Printing", symbol: "printer.fill", category: "work", keywords: ["printer", "office", "supplies", "paper", "print"]),
        CategoryIconItem(id: "Calculator", name: "Accounting", symbol: "number", category: "work", keywords: ["calculator", "math", "accounting", "audit", "tax"]),

        // Finance & Wealth
        CategoryIconItem(id: "DollarSign", name: "Income / Cash", symbol: "dollarsign.circle.fill", category: "finance", keywords: ["money", "salary", "income", "cash", "dollar", "usd"]),
        CategoryIconItem(id: "Wallet", name: "Wallet", symbol: "creditcard.fill", category: "finance", keywords: ["wallet", "pocket", "cash", "money", "budget"]),
        CategoryIconItem(id: "Coins", name: "Coins / Crypto", symbol: "centsign.circle.fill", category: "finance", keywords: ["coins", "change", "crypto", "gold", "currency"]),
        CategoryIconItem(id: "TrendingUp", name: "Investments", symbol: "chart.line.uptrend.xyaxis", category: "finance", keywords: ["invest", "stock", "growth", "market", "profit", "trading"]),
        CategoryIconItem(id: "PiggyBank", name: "Savings", symbol: "banknote.fill", category: "finance", keywords: ["savings", "piggy bank", "deposit", "save", "emergency"]),
        CategoryIconItem(id: "Percent", name: "Dividends / Yield", symbol: "percent", category: "finance", keywords: ["percent", "interest", "dividend", "discount", "yield"]),
        CategoryIconItem(id: "Receipt", name: "Receipts", symbol: "doc.plaintext.fill", category: "finance", keywords: ["receipt", "bill", "expense", "invoice", "check"]),
        CategoryIconItem(id: "Vault", name: "Vault", symbol: "lock.shield.fill", category: "finance", keywords: ["vault", "safe", "security", "assets", "treasury"]),
        CategoryIconItem(id: "Landmark", name: "Bank / Gov", symbol: "building.columns.fill", category: "finance", keywords: ["bank", "institution", "finance", "government", "tax"]),
        CategoryIconItem(id: "BadgePercent", name: "Rewards / Cashback", symbol: "percent", category: "finance", keywords: ["promotion", "cashback", "bonus", "rewards", "discount"]),
        CategoryIconItem(id: "ArrowUpRight", name: "Transfers", symbol: "arrow.up.right", category: "finance", keywords: ["transfer", "send", "payment", "payout", "flow"]),
        CategoryIconItem(id: "BarChart3", name: "Analytics", symbol: "chart.bar.fill", category: "finance", keywords: ["chart", "analytics", "report", "statistics", "graph"]),

        // Family, Pets & Life
        CategoryIconItem(id: "Baby", name: "Kids / Baby", symbol: "stroller.fill", category: "life", keywords: ["baby", "child", "kid", "nursery", "parenting", "toy"]),
        CategoryIconItem(id: "Dog", name: "Pets", symbol: "pawprint.fill", category: "life", keywords: ["dog", "pet", "puppy", "vet", "animal", "cat"]),
        CategoryIconItem(id: "Users", name: "Family & Social", symbol: "person.2.fill", category: "life", keywords: ["family", "friends", "people", "team", "group", "community"]),
        CategoryIconItem(id: "User", name: "Personal", symbol: "person.fill", category: "life", keywords: ["personal", "self", "individual", "profile"]),
        CategoryIconItem(id: "Sparkles", name: "Special / Treats", symbol: "sparkles", category: "life", keywords: ["sparkle", "magic", "special", "beauty", "luxury", "treat"]),
        CategoryIconItem(id: "SmilePlus", name: "Joy / Hobby", symbol: "face.smiling.fill", category: "life", keywords: ["happiness", "wellbeing", "good", "joy", "smile"]),

        // Services & Tools
        CategoryIconItem(id: "Wrench", name: "Repairs", symbol: "wrench.fill", category: "tools", keywords: ["wrench", "repair", "maintenance", "fix", "tools", "service"]),
        CategoryIconItem(id: "Hammer", name: "Renovation", symbol: "hammer.fill", category: "tools", keywords: ["hammer", "construction", "renovation", "build", "tools"]),
        CategoryIconItem(id: "Scissors", name: "Grooming", symbol: "scissors", category: "tools", keywords: ["scissors", "haircut", "barber", "salon", "craft", "tailor"]),
        CategoryIconItem(id: "ShieldCheck", name: "Security", symbol: "checkmark.shield.fill", category: "tools", keywords: ["verified", "security", "warranty", "guarantee", "safe"]),
        CategoryIconItem(id: "Lock", name: "Privacy", symbol: "lock.fill", category: "tools", keywords: ["lock", "security", "privacy", "safe", "pass"]),
        CategoryIconItem(id: "Settings", name: "Settings", symbol: "gearshape.fill", category: "tools", keywords: ["settings", "gear", "config", "maintenance", "system"])
    ]

    var filteredIcons: [CategoryIconItem] {
        let query = searchText.trimmingCharacters(in: .whitespaces).lowercased()
        return allIcons.filter { item in
            let matchesCategory = selectedCategoryFilter == "all" || item.category == selectedCategoryFilter
            if !matchesCategory { return false }

            if query.isEmpty { return true }
            let matchesName = item.name.lowercased().contains(query) || item.id.lowercased().contains(query)
            let matchesKeyword = item.keywords.contains { $0.lowercased().contains(query) }
            return matchesName || matchesKeyword
        }
    }

    var activeThemeColor: Color {
        Color(hex: selectedColorHex)
    }

    var selectedSymbol: String {
        CategoryIconHelper.sfSymbol(forIcon: selectedIcon, categoryName: name)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color(hex: "0d1117").ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 20) {
                        // 1. Type Segmented Control
                        HStack(spacing: 6) {
                            ForEach(CategoryTypeOption.allCases, id: \.self) { opt in
                                Button {
                                    withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
                                        type = opt
                                    }
                                } label: {
                                    HStack(spacing: 6) {
                                        Image(systemName: opt.icon)
                                            .font(.caption.bold())
                                        Text(opt.displayName)
                                            .font(.subheadline.bold())
                                    }
                                    .foregroundColor(type == opt ? .white : Color.white.opacity(0.5))
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 10)
                                    .background(
                                        type == opt ?
                                        LinearGradient(
                                            colors: [activeThemeColor.opacity(0.85), activeThemeColor],
                                            startPoint: .leading, endPoint: .trailing
                                        ) :
                                        LinearGradient(
                                            colors: [Color.white.opacity(0.04), Color.white.opacity(0.04)],
                                            startPoint: .leading, endPoint: .trailing
                                        )
                                    )
                                    .clipShape(RoundedRectangle(cornerRadius: 10))
                                    .shadow(color: type == opt ? activeThemeColor.opacity(0.3) : .clear, radius: 4)
                                }
                            }
                        }
                        .padding(4)
                        .background(Color.white.opacity(0.03))
                        .clipShape(RoundedRectangle(cornerRadius: 14))

                        // 2. Name & Dynamic Icon Preview Card
                        VStack(alignment: .leading, spacing: 8) {
                            Text("CATEGORY NAME")
                                .font(.system(size: 11, weight: .semibold, design: .rounded))
                                .foregroundColor(Color.white.opacity(0.6))

                            HStack(spacing: 12) {
                                // Live icon swatch
                                ZStack {
                                    RoundedRectangle(cornerRadius: 14)
                                        .fill(activeThemeColor.opacity(0.2))
                                        .frame(width: 48, height: 48)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 14)
                                                .stroke(activeThemeColor.opacity(0.6), lineWidth: 1.5)
                                        )
                                        .shadow(color: activeThemeColor.opacity(0.35), radius: 8)

                                    Image(systemName: selectedSymbol)
                                        .font(.system(size: 22, weight: .semibold))
                                        .foregroundColor(activeThemeColor)
                                }

                                TextField("e.g. Groceries, Gym, Freelance...", text: $name)
                                    .textFieldStyle(.plain)
                                    .foregroundColor(.white)
                                    .font(.body)
                                    .padding(14)
                                    .background(Color.white.opacity(0.06))
                                    .clipShape(RoundedRectangle(cornerRadius: 12))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(Color.white.opacity(0.1), lineWidth: 1)
                                    )
                            }
                        }

                        // 3. Color Selection (Palette + ColorPicker + Hex Field)
                        VStack(alignment: .leading, spacing: 10) {
                            HStack {
                                Text("THEME COLOR")
                                    .font(.system(size: 11, weight: .semibold, design: .rounded))
                                    .foregroundColor(Color.white.opacity(0.6))
                                Spacer()

                                // Hex Code text field badge
                                HStack(spacing: 4) {
                                    Circle()
                                        .fill(activeThemeColor)
                                        .frame(width: 10, height: 10)
                                        .shadow(color: activeThemeColor, radius: 4)

                                    Text("#")
                                        .font(.system(size: 12, weight: .bold, design: .monospaced))
                                        .foregroundColor(Color.white.opacity(0.5))

                                    TextField("818cf8", text: $hexInput)
                                        .textFieldStyle(.plain)
                                        .font(.system(size: 12, weight: .semibold, design: .monospaced))
                                        .foregroundColor(.white)
                                        .frame(width: 60)
                                        .textCase(.uppercase)
                                        .autocorrectionDisabled()
                                        .onChange(of: hexInput) { _, newValue in
                                            let clean = newValue.filter { $0.isHexDigit }
                                            if clean.count == 6 {
                                                selectedColorHex = clean
                                                customColor = Color(hex: clean)
                                            }
                                        }
                                }
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.white.opacity(0.06))
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                                )
                            }

                            // Color swatches + ColorPicker
                            LazyVGrid(columns: [GridItem(.adaptive(minimum: 36))], spacing: 10) {
                                ForEach(colorOptions, id: \.self) { c in
                                    let isSelected = selectedColorHex.lowercased() == c.lowercased()
                                    Circle()
                                        .fill(Color(hex: c))
                                        .frame(width: 34, height: 34)
                                        .overlay(
                                            Circle()
                                                .stroke(Color.white, lineWidth: isSelected ? 3 : 0)
                                        )
                                        .shadow(color: isSelected ? Color(hex: c).opacity(0.7) : Color.clear, radius: 6)
                                        .scaleEffect(isSelected ? 1.15 : 1.0)
                                        .onTapGesture {
                                            withAnimation(.easeInOut(duration: 0.15)) {
                                                selectedColorHex = c
                                                hexInput = c
                                                customColor = Color(hex: c)
                                            }
                                        }
                                }

                                // Native Apple ColorPicker button
                                ColorPicker("", selection: $customColor, supportsOpacity: false)
                                    .labelsHidden()
                                    .frame(width: 34, height: 34)
                                    .background(
                                        LinearGradient(
                                            colors: [Color.red, Color.yellow, Color.green, Color.blue, Color.purple],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                    .clipShape(Circle())
                                    .overlay(
                                        Circle()
                                            .stroke(Color.white.opacity(0.5), lineWidth: 2)
                                    )
                                    .shadow(color: Color.black.opacity(0.3), radius: 4)
                                    .onChange(of: customColor) { _, newColor in
                                        let hex = newColor.toHex()
                                        selectedColorHex = hex
                                        hexInput = hex
                                    }
                            }
                            .padding(12)
                            .background(Color.white.opacity(0.04))
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                            .overlay(
                                RoundedRectangle(cornerRadius: 14)
                                    .stroke(Color.white.opacity(0.06), lineWidth: 1)
                            )
                        }

                        // 4. Icon Picker Section (Search + Category Filter + Grid)
                        VStack(alignment: .leading, spacing: 10) {
                            HStack {
                                Text("SELECT ICON (\(filteredIcons.count))")
                                    .font(.system(size: 11, weight: .semibold, design: .rounded))
                                    .foregroundColor(Color.white.opacity(0.6))
                                Spacer()
                            }

                            // Search bar
                            HStack(spacing: 8) {
                                Image(systemName: "magnifyingglass")
                                    .font(.system(size: 14))
                                    .foregroundColor(Color.white.opacity(0.5))

                                TextField("Search icons...", text: $searchText)
                                    .textFieldStyle(.plain)
                                    .font(.subheadline)
                                    .foregroundColor(.white)

                                if !searchText.isEmpty {
                                    Button {
                                        searchText = ""
                                    } label: {
                                        Image(systemName: "xmark.circle.fill")
                                            .foregroundColor(Color.white.opacity(0.5))
                                    }
                                }
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(Color.white.opacity(0.05))
                            .clipShape(RoundedRectangle(cornerRadius: 10))

                            // Category filter chips
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 6) {
                                    ForEach(filterCategories, id: \.id) { cat in
                                        let isCatSelected = selectedCategoryFilter == cat.id
                                        Button {
                                            withAnimation(.easeInOut(duration: 0.15)) {
                                                selectedCategoryFilter = cat.id
                                            }
                                        } label: {
                                            Text(cat.title)
                                                .font(.system(size: 12, weight: isCatSelected ? .bold : .medium))
                                                .padding(.horizontal, 10)
                                                .padding(.vertical, 5)
                                                .background(
                                                    isCatSelected ? activeThemeColor.opacity(0.25) : Color.white.opacity(0.04)
                                                )
                                                .foregroundColor(isCatSelected ? activeThemeColor : Color.white.opacity(0.6))
                                                .clipShape(Capsule())
                                                .overlay(
                                                    Capsule()
                                                        .stroke(isCatSelected ? activeThemeColor : Color.white.opacity(0.08), lineWidth: 1)
                                                )
                                        }
                                    }
                                }
                                .padding(.vertical, 2)
                            }

                            // Scrollable Icon Grid
                            ScrollView {
                                LazyVGrid(columns: [GridItem(.adaptive(minimum: 44))], spacing: 8) {
                                    ForEach(filteredIcons) { item in
                                        let isSelected = selectedIcon == item.id
                                        Button {
                                            withAnimation(.easeInOut(duration: 0.15)) {
                                                selectedIcon = item.id
                                            }
                                        } label: {
                                            ZStack {
                                                RoundedRectangle(cornerRadius: 10)
                                                    .fill(isSelected ? activeThemeColor.opacity(0.25) : Color.white.opacity(0.03))
                                                    .frame(height: 44)
                                                    .overlay(
                                                        RoundedRectangle(cornerRadius: 10)
                                                            .stroke(isSelected ? activeThemeColor : Color.white.opacity(0.05), lineWidth: isSelected ? 2 : 1)
                                                    )
                                                    .shadow(color: isSelected ? activeThemeColor.opacity(0.3) : .clear, radius: 4)

                                                Image(systemName: item.symbol)
                                                    .font(.system(size: 17, weight: .bold))
                                                    .foregroundColor(isSelected ? activeThemeColor : Color.white.opacity(0.7))
                                            }
                                        }
                                    }
                                }
                                .padding(10)
                            }
                            .frame(maxHeight: 180)
                            .background(Color.white.opacity(0.03))
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                            .overlay(
                                RoundedRectangle(cornerRadius: 14)
                                    .stroke(Color.white.opacity(0.06), lineWidth: 1)
                            )
                        }

                        // Error message
                        if let error = errorMessage {
                            HStack {
                                Image(systemName: "exclamationmark.triangle.fill")
                                Text(error).font(.caption)
                            }
                            .foregroundColor(Color(hex: "f87171"))
                            .padding(12)
                            .background(Color(hex: "f87171").opacity(0.12))
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                        }

                        // Save Button
                        Button {
                            Task { await save() }
                        } label: {
                            Group {
                                if isLoading {
                                    ProgressView().tint(.white)
                                } else {
                                    HStack(spacing: 8) {
                                        Image(systemName: "plus.circle.fill")
                                        Text("Create Category")
                                            .font(.headline.bold())
                                    }
                                    .foregroundColor(.white)
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .padding(16)
                            .background(
                                LinearGradient(
                                    colors: [activeThemeColor.opacity(0.9), activeThemeColor],
                                    startPoint: .leading, endPoint: .trailing
                                )
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                            .shadow(color: activeThemeColor.opacity(0.4), radius: 10, x: 0, y: 5)
                        }
                        .disabled(isLoading || name.trimmingCharacters(in: .whitespaces).isEmpty)
                    }
                    .padding(20)
                }
            }
            .navigationTitle("New Category")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundColor(Color(hex: "a78bfa"))
                }
            }
            .onAppear {
                type = initialType
                if initialType == .income {
                    selectedColorHex = "10b981"
                    hexInput = "10b981"
                    customColor = Color(hex: "10b981")
                }
            }
        }
    }

    private func save() async {
        let trimmedName = name.trimmingCharacters(in: .whitespaces)
        guard !trimmedName.isEmpty else { return }

        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        let payload = CreateCategoryPayload(
            name: trimmedName,
            type: type.rawValue,
            parentCategoryId: nil,
            icon: selectedIcon,
            color: selectedColorHex.hasPrefix("#") ? selectedColorHex : "#\(selectedColorHex)"
        )

        do {
            let created = try await CategoryService.shared.createCategory(payload)
            onSuccess(created)
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
