import SwiftUI

// MARK: - Category Icon Model
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
    @State private var selectedIcon: String = "tag.fill"
    @State private var selectedColorHex: String = "ef4444"
    @State private var hexInput: String = "ef4444"
    @State private var customColor: Color = Color(hex: "ef4444")
    @State private var searchText: String = ""
    @State private var selectedCategoryFilter: String = "all"
    @State private var isLoading: Bool = false
    @State private var errorMessage: String?

    // Color swatches (16 vibrant colors)
    let colorOptions: [String] = [
        "ef4444", "f97316", "f59e0b", "eab308",
        "84cc16", "22c55e", "10b981", "14b8a6",
        "06b6d4", "38bdf8", "3b82f6", "6366f1",
        "8b5cf6", "a855f7", "ec4899", "64748b"
    ]

    var filterCategories: [(id: String, title: String)] {
        [
            ("all", L10n.Categories.filterAll),
            ("food", L10n.Categories.filterFood),
            ("shopping", L10n.Categories.filterShopping),
            ("transport", L10n.Categories.filterTransport),
            ("housing", L10n.Categories.filterHousing),
            ("health", L10n.Categories.filterHealth),
            ("fun", L10n.Categories.filterEntertainment),
            ("work", L10n.Categories.filterWork),
            ("finance", L10n.Categories.filterFinance),
            ("life", L10n.Categories.filterLife),
            ("tools", L10n.Categories.filterTools)
        ]
    }

    let allIcons: [CategoryIconItem] = [
        // Food & Dining
        CategoryIconItem(id: "Utensils", name: "Restaurant", symbol: "fork.knife", category: "food", keywords: ["food", "restaurant", "dining", "meal", "dinner", "lunch"]),
        CategoryIconItem(id: "UtensilsCrossed", name: "Dining Out", symbol: "fork.knife.circle.fill", category: "food", keywords: ["food", "restaurant", "cafe", "eat"]),
        CategoryIconItem(id: "Coffee", name: "Coffee & Tea", symbol: "cup.and.saucer.fill", category: "food", keywords: ["coffee", "tea", "cafe", "latte", "espresso", "starbucks", "drink"]),
        CategoryIconItem(id: "Pizza", name: "Fast Food", symbol: "takeoutbag.and.cup.and.straw.fill", category: "food", keywords: ["fast food", "pizza", "burger", "takeout", "delivery"]),
        CategoryIconItem(id: "Beer", name: "Beer & Drinks", symbol: "mug.fill", category: "food", keywords: ["beer", "alcohol", "bar", "pub", "brewery", "drink"]),
        CategoryIconItem(id: "Wine", name: "Wine & Spirits", symbol: "wineglass.fill", category: "food", keywords: ["wine", "alcohol", "bar", "cocktail", "liquor"]),
        CategoryIconItem(id: "Apple", name: "Groceries", symbol: "apple.logo", category: "food", keywords: ["fruit", "apple", "food", "healthy", "snack"]),
        CategoryIconItem(id: "Cake", name: "Bakery", symbol: "birthday.cake.fill", category: "food", keywords: ["cake", "dessert", "bakery", "pastry", "sweet", "birthday"]),
        CategoryIconItem(id: "Cookie", name: "Snacks", symbol: "circle.hexagongrid.fill", category: "food", keywords: ["cookie", "snack", "sweets", "candy"]),
        CategoryIconItem(id: "Fish", name: "Seafood", symbol: "fish.fill", category: "food", keywords: ["fish", "seafood", "sushi", "salmon", "market"]),
        CategoryIconItem(id: "Soup", name: "Soup & Bowls", symbol: "cup.and.saucer.fill", category: "food", keywords: ["soup", "bowl", "ramen", "noodle", "warm"]),

        // Shopping & Retail
        CategoryIconItem(id: "ShoppingBag", name: "Shopping", symbol: "bag.fill", category: "shopping", keywords: ["shopping", "bag", "clothes", "mall", "purchase"]),
        CategoryIconItem(id: "ShoppingCart", name: "Supermarket", symbol: "cart.fill", category: "shopping", keywords: ["cart", "supermarket", "groceries", "store", "market"]),
        CategoryIconItem(id: "Store", name: "Department Store", symbol: "storefront.fill", category: "shopping", keywords: ["store", "shop", "market", "retail", "mall"]),
        CategoryIconItem(id: "Tag", name: "Discounts & Sales", symbol: "tag.fill", category: "shopping", keywords: ["tag", "sale", "discount", "offer", "deal", "promo"]),
        CategoryIconItem(id: "Gift", name: "Gifts & Donations", symbol: "gift.fill", category: "shopping", keywords: ["gift", "present", "donation", "charity", "holiday", "birthday"]),
        CategoryIconItem(id: "Package", name: "Online Orders", symbol: "shippingbox.fill", category: "shopping", keywords: ["package", "delivery", "amazon", "courier", "shipping"]),
        CategoryIconItem(id: "Shirt", name: "Clothing", symbol: "tshirt.fill", category: "shopping", keywords: ["clothing", "shirt", "clothes", "apparel", "fashion"]),
        CategoryIconItem(id: "Watch", name: "Jewelry & Luxury", symbol: "applewatch", category: "shopping", keywords: ["watch", "jewelry", "accessory", "luxury", "gold"]),
        CategoryIconItem(id: "Glasses", name: "Optics & Style", symbol: "eyeglasses", category: "shopping", keywords: ["glasses", "optics", "sunglasses", "vision"]),
        CategoryIconItem(id: "Footprints", name: "Shoes", symbol: "shoeprints.fill", category: "shopping", keywords: ["shoes", "boots", "sneakers", "footwear"]),
        CategoryIconItem(id: "CreditCard", name: "Subscriptions", symbol: "creditcard.fill", category: "shopping", keywords: ["card", "payment", "bank", "subscription", "recurring"]),

        // Transport & Travel
        CategoryIconItem(id: "Car", name: "Auto & Vehicle", symbol: "car.fill", category: "transport", keywords: ["car", "auto", "vehicle", "drive", "parking"]),
        CategoryIconItem(id: "Fuel", name: "Gas & Fuel", symbol: "fuelpump.fill", category: "transport", keywords: ["fuel", "gas", "petrol", "diesel", "station"]),
        CategoryIconItem(id: "Bus", name: "Public Transit", symbol: "bus.fill", category: "transport", keywords: ["bus", "transit", "metro", "subway", "ticket", "public"]),
        CategoryIconItem(id: "Plane", name: "Flights & Travel", symbol: "airplane", category: "transport", keywords: ["airplane", "flight", "travel", "vacation", "trip", "airline"]),
        CategoryIconItem(id: "Train", name: "Train & Rail", symbol: "tram.fill", category: "transport", keywords: ["train", "rail", "metro", "commute"]),
        CategoryIconItem(id: "Bike", name: "Bicycle", symbol: "bicycle", category: "transport", keywords: ["bike", "cycling", "bicycle", "scooter", "eco"]),
        CategoryIconItem(id: "Ship", name: "Cruise & Ferry", symbol: "ferry.fill", category: "transport", keywords: ["boat", "ship", "ferry", "cruise", "sea", "water"]),
        CategoryIconItem(id: "MapPin", name: "Taxi & Rides", symbol: "mappin.and.ellipse", category: "transport", keywords: ["taxi", "uber", "bolt", "lyft", "ride", "cab"]),
        CategoryIconItem(id: "Navigation", name: "Navigation", symbol: "location.fill", category: "transport", keywords: ["gps", "map", "location", "toll", "highway"]),
        CategoryIconItem(id: "Luggage", name: "Vacation", symbol: "suitcase.fill", category: "transport", keywords: ["luggage", "vacation", "holiday", "hotel", "resort"]),
        CategoryIconItem(id: "Ticket", name: "Tickets", symbol: "ticket.fill", category: "transport", keywords: ["ticket", "entry", "pass", "booking", "event"]),
        CategoryIconItem(id: "Compass", name: "Adventures", symbol: "safari.fill", category: "transport", keywords: ["compass", "safari", "explore", "tour", "guide"]),

        // Housing & Utilities
        CategoryIconItem(id: "Home", name: "Rent & Mortgage", symbol: "house.fill", category: "housing", keywords: ["home", "house", "rent", "mortgage", "apartment", "realty"]),
        CategoryIconItem(id: "Building", name: "Property", symbol: "building.fill", category: "housing", keywords: ["building", "property", "hoa", "maintenance", "office"]),
        CategoryIconItem(id: "Building2", name: "Commercial", symbol: "building.2.fill", category: "housing", keywords: ["city", "condo", "development", "architecture"]),
        CategoryIconItem(id: "Zap", name: "Electricity", symbol: "bolt.fill", category: "housing", keywords: ["power", "electricity", "energy", "utility", "electric", "bill"]),
        CategoryIconItem(id: "Droplets", name: "Water Supply", symbol: "drop.fill", category: "housing", keywords: ["water", "utility", "sewer", "plumbing", "bill"]),
        CategoryIconItem(id: "Flame", name: "Heating & Gas", symbol: "flame.fill", category: "housing", keywords: ["gas", "heat", "heating", "fire", "winter", "utility"]),
        CategoryIconItem(id: "Wifi", name: "Internet", symbol: "wifi", category: "housing", keywords: ["internet", "wifi", "broadband", "network", "fiber", "provider"]),
        CategoryIconItem(id: "Tv", name: "Cable & Media", symbol: "tv.fill", category: "housing", keywords: ["tv", "cable", "television", "streaming", "netflix", "media"]),
        CategoryIconItem(id: "Trash2", name: "Waste Management", symbol: "trash.fill", category: "housing", keywords: ["trash", "garbage", "cleaning", "recycling", "waste"]),
        CategoryIconItem(id: "Key", name: "Security & Keys", symbol: "key.fill", category: "housing", keywords: ["key", "locksmith", "access", "safe"]),
        CategoryIconItem(id: "Lightbulb", name: "Home Improvement", symbol: "lightbulb.fill", category: "housing", keywords: ["light", "bulb", "decor", "interior", "furniture", "ikea"]),
        CategoryIconItem(id: "Bed", name: "Furniture", symbol: "bed.double.fill", category: "housing", keywords: ["bed", "furniture", "hotel", "bedroom", "rest"]),
        CategoryIconItem(id: "Bath", name: "Bath & Clean", symbol: "shower.fill", category: "housing", keywords: ["bath", "shower", "cleaning", "hygiene", "soap"]),

        // Health & Fitness
        CategoryIconItem(id: "Heart", name: "Healthcare", symbol: "heart.fill", category: "health", keywords: ["heart", "health", "care", "wellness", "doctor"]),
        CategoryIconItem(id: "HeartPulse", name: "Medical Checkup", symbol: "heart.text.square.fill", category: "health", keywords: ["medical", "clinic", "hospital", "test", "doctor", "health"]),
        CategoryIconItem(id: "Activity", name: "Fitness & Sport", symbol: "waveform.path.ecg", category: "health", keywords: ["fitness", "sports", "workout", "cardio", "training", "gym"]),
        CategoryIconItem(id: "Dumbbell", name: "Gym Membership", symbol: "dumbbell.fill", category: "health", keywords: ["gym", "workout", "muscle", "crossfit", "training"]),
        CategoryIconItem(id: "Pill", name: "Pharmacy", symbol: "pills.fill", category: "health", keywords: ["pharmacy", "medicine", "pill", "drugs", "vitamins", "prescription"]),
        CategoryIconItem(id: "Stethoscope", name: "Doctor Visits", symbol: "stethoscope", category: "health", keywords: ["doctor", "physician", "consultation", "therapy", "specialist"]),
        CategoryIconItem(id: "Crosshair", name: "Target Sport", symbol: "target", category: "health", keywords: ["target", "sport", "hobby", "focus", "archery"]),
        CategoryIconItem(id: "Shield", name: "Health Insurance", symbol: "shield.fill", category: "health", keywords: ["insurance", "policy", "coverage", "protection", "security"]),
        CategoryIconItem(id: "Smile", name: "Dental Care", symbol: "face.smiling.inverse", category: "health", keywords: ["dental", "teeth", "dentist", "smile", "hygiene"]),
        CategoryIconItem(id: "Hospital", name: "Hospital", symbol: "cross.case.fill", category: "health", keywords: ["hospital", "emergency", "clinic", "surgery", "care"]),

        // Entertainment & Fun
        CategoryIconItem(id: "Film", name: "Cinema & Movies", symbol: "film.fill", category: "fun", keywords: ["cinema", "movie", "film", "theatre", "hollywood"]),
        CategoryIconItem(id: "Music", name: "Music & Streaming", symbol: "music.note", category: "fun", keywords: ["music", "concert", "spotify", "apple music", "song", "audio"]),
        CategoryIconItem(id: "Gamepad2", name: "Gaming", symbol: "gamecontroller.fill", category: "fun", keywords: ["game", "gaming", "playstation", "xbox", "steam", "nintendo"]),
        CategoryIconItem(id: "Tv2", name: "Shows & Media", symbol: "play.tv.fill", category: "fun", keywords: ["tv", "show", "series", "youtube", "media", "streaming"]),
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
                        typeSelectorSection
                        nameAndPreviewSection
                        colorPickerSection
                        iconPickerSection

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

                        saveButtonSection
                    }
                    .padding(20)
                }
            }
            .navigationTitle(L10n.Categories.modalCreateTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(L10n.Common.cancel) { dismiss() }
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

    // MARK: - Subviews
    private var typeSelectorSection: some View {
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
    }

    private var nameAndPreviewSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(L10n.Categories.categoryName.uppercased())
                .font(.system(size: 11, weight: .semibold, design: .rounded))
                .foregroundColor(Color.white.opacity(0.5))

            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(activeThemeColor.opacity(0.2))
                        .frame(width: 48, height: 48)
                        .overlay(
                            Circle()
                                .stroke(activeThemeColor.opacity(0.4), lineWidth: 1.5)
                        )
                        .shadow(color: activeThemeColor.opacity(0.4), radius: 6)

                    Image(systemName: selectedSymbol)
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(activeThemeColor)
                }

                TextField(L10n.Categories.namePlaceholder, text: $name)
                    .font(.headline.weight(.semibold))
                    .foregroundColor(.white)
                    .textFieldStyle(.plain)
                    .autocorrectionDisabled()
            }
            .padding(14)
            .background(Color.white.opacity(0.05))
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.white.opacity(0.08), lineWidth: 1)
            )
        }
    }

    private var colorPickerSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(L10n.Categories.selectColor.uppercased())
                    .font(.system(size: 11, weight: .semibold, design: .rounded))
                    .foregroundColor(Color.white.opacity(0.5))

                Spacer()

                HStack(spacing: 6) {
                    Text("#")
                        .font(.system(size: 12, weight: .bold, design: .monospaced))
                        .foregroundColor(Color.white.opacity(0.4))

                    TextField("HEX", text: $hexInput)
                        .font(.system(size: 12, weight: .bold, design: .monospaced))
                        .foregroundColor(.white)
                        .frame(width: 55)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.never)
                        .onChange(of: hexInput) { _, val in
                            let clean = val.replacingOccurrences(of: "#", with: "").trimmingCharacters(in: .whitespaces)
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

            LazyVGrid(columns: [GridItem(.adaptive(minimum: 36))], spacing: 10) {
                ForEach(colorOptions, id: \.self) { c in
                    colorSwatch(for: c)
                }

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
        }
        .padding(16)
        .background(Color.white.opacity(0.03))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.white.opacity(0.06), lineWidth: 1)
        )
    }

    private var iconPickerSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(L10n.Categories.selectIcon.uppercased())
                .font(.system(size: 11, weight: .semibold, design: .rounded))
                .foregroundColor(Color.white.opacity(0.5))

            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(Color.white.opacity(0.4))
                    .font(.caption)

                TextField(L10n.Categories.searchIcons, text: $searchText)
                    .font(.subheadline)
                    .foregroundColor(.white)
                    .autocorrectionDisabled()

                if !searchText.isEmpty {
                    Button {
                        searchText = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(Color.white.opacity(0.4))
                            .font(.caption)
                    }
                }
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .background(Color.white.opacity(0.05))
            .clipShape(RoundedRectangle(cornerRadius: 10))

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

            ScrollView {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 44))], spacing: 8) {
                    ForEach(filteredIcons) { item in
                        iconButton(for: item)
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
        .padding(16)
        .background(Color.white.opacity(0.03))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.white.opacity(0.06), lineWidth: 1)
        )
    }

    private var saveButtonSection: some View {
        Button {
            Task { await save() }
        } label: {
            Group {
                if isLoading {
                    ProgressView().tint(.white)
                } else {
                    HStack(spacing: 8) {
                        Image(systemName: "plus.circle.fill")
                        Text(L10n.Categories.createCategory)
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

    @ViewBuilder
    private func colorSwatch(for c: String) -> some View {
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
                selectedColorHex = c
                hexInput = c
                customColor = Color(hex: c)
            }
    }

    @ViewBuilder
    private func iconButton(for item: CategoryIconItem) -> some View {
        let isSelected = selectedIcon == item.id
        Button {
            withAnimation(.easeInOut(duration: 0.15)) {
                selectedIcon = item.id
            }
        } label: {
            ZStack {
                let fillCol = isSelected ? activeThemeColor.opacity(0.25) : Color.white.opacity(0.03)
                let strokeCol = isSelected ? activeThemeColor : Color.white.opacity(0.05)
                let strokeWidth: CGFloat = isSelected ? 2.0 : 1.0

                RoundedRectangle(cornerRadius: 10)
                    .fill(fillCol)
                    .frame(height: 44)
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(strokeCol, lineWidth: strokeWidth)
                    )

                Image(systemName: item.symbol)
                    .font(.system(size: 17, weight: .bold))
                    .foregroundColor(isSelected ? activeThemeColor : Color.white.opacity(0.7))
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
