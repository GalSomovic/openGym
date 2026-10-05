import Foundation

/// Eating-disorder support services, one or two per country. Every number and address was
/// checked on the organisation's own website; sources and dates are in
/// apple/research/COMPLIANCE.md. Re-check them before each release.
struct Helpline: Identifiable, Hashable {
    /// ISO 3166-1 region code; empty for the international directory.
    let region: String
    let name: String
    /// As the organisation writes it.
    var phone: String? = nil
    /// What the Phone app dials, when it differs from the digits in `phone`.
    var dial: String? = nil
    let url: URL
    var note: String? = nil

    var id: String { region + name }

    /// The country's name in the phone's language.
    var country: String {
        region.isEmpty ? String(localized: "Any country") : Locale.current.localizedString(forRegionCode: region) ?? region
    }

    /// The services for `region` first; if there are none, the international directory takes
    /// their place. The rest by country name, with the international directory last.
    static func split(for region: String?) -> (local: [Helpline], others: [Helpline]) {
        let local = all.filter { $0.region == region && !$0.region.isEmpty }
        if local.isEmpty {
            return (all.filter { $0.region.isEmpty }, all.filter { !$0.region.isEmpty }.sorted(by: Self.byCountry))
        }
        let rest = all.filter { $0.region != region }
        return (local, rest.filter { !$0.region.isEmpty }.sorted(by: Self.byCountry) + rest.filter { $0.region.isEmpty })
    }

    private static func byCountry(_ a: Helpline, _ b: Helpline) -> Bool {
        a.country.localizedStandardCompare(b.country) == .orderedAscending
    }

    static let all: [Helpline] = [
        Helpline(region: "US", name: "ANAD Helpline", phone: "1-888-375-7767", dial: "+18883757767",
                 url: URL(string: "https://anad.org/eating-disorder-helpline/")!,
                 note: String(localized: "Free peer support. Monday to Friday, 9am–9pm Central.")),
        Helpline(region: "US", name: "National Alliance for Eating Disorders", phone: "(866) 662-1235", dial: "+18666621235",
                 url: URL(string: "https://www.allianceforeatingdisorders.com/")!,
                 note: String(localized: "Answered by therapists. Monday to Friday, 9am–7pm Eastern.")),
        Helpline(region: "GB", name: "Beat", phone: "0808 801 0677", dial: "08088010677",
                 url: URL(string: "https://www.beateatingdisorders.org.uk/get-information-and-support/get-help-for-myself/i-need-support-now/helplines/")!,
                 note: String(localized: "Free, Monday to Friday 3pm–8pm. England; Scotland 0808 801 0432, Wales 0808 801 0433, Northern Ireland 0808 801 0434.")),
        Helpline(region: "IE", name: "Bodywhys", phone: "01 210 7906", dial: "+35312107906",
                 url: URL(string: "https://www.bodywhys.ie/supports/helpline/")!,
                 note: String(localized: "The Eating Disorders Association of Ireland. Evening and morning sessions; see the website for times.")),
        Helpline(region: "CA", name: "NEDIC", phone: "1-866-633-4220", dial: "+18666334220",
                 url: URL(string: "https://nedic.ca/")!,
                 note: String(localized: "National Eating Disorder Information Centre. Free; phone Monday to Friday (Eastern), live chat on the website.")),
        Helpline(region: "AU", name: "Butterfly National Helpline", phone: "1800 33 4673", dial: "1800334673",
                 url: URL(string: "https://butterfly.org.au/get-support/helpline/")!,
                 note: String(localized: "Free, 7 days, 8am–midnight. Webchat and email too.")),
        Helpline(region: "NZ", name: "1737, Need to talk?", phone: "1737", dial: "1737",
                 url: URL(string: "https://1737.org.nz/")!,
                 note: String(localized: "Free call or text, any time, with a trained counsellor.")),
        Helpline(region: "NZ", name: "EDANZ", phone: "0800 2 EDANZ", dial: "0800233269",
                 url: URL(string: "https://www.ed.org.nz/")!,
                 note: String(localized: "Support for families and carers of someone with an eating disorder.")),
        Helpline(region: "IL", name: "Enosh · מרכז המידע להפרעות אכילה", phone: "074-7556155", dial: "+97247556155",
                 url: URL(string: "https://www.enosh.org.il/he/eating-disorders/")!,
                 note: String(localized: "Enosh eating-disorder information centre, in Hebrew. Sunday to Thursday, 8:00–15:30.")),
        Helpline(region: "IL", name: "ERAN · ער״ן", phone: "1201", dial: "1201",
                 url: URL(string: "https://www.eran.org.il/")!,
                 note: String(localized: "ERAN emotional first aid. Free and anonymous, any time; also chat and WhatsApp.")),
        Helpline(region: "DE", name: "BIÖG Telefonberatung Essstörungen", phone: "0221 892031", dial: "+49221892031",
                 url: URL(string: "https://essstoerungen.bioeg.de/")!,
                 note: String(localized: "Federal Institute for Public Health (formerly BZgA). Every day; normal call rate to Cologne.")),
        Helpline(region: "FR", name: "Anorexie Boulimie Info Écoute", phone: "09 69 325 900", dial: "+33969325900",
                 url: URL(string: "https://www.ffab.fr/trouver-de-l-aide/permanence-telephonique")!,
                 note: String(localized: "French Federation for Anorexia and Bulimia (FFAB). Normal call rate; afternoons on weekdays except Wednesday.")),
        Helpline(region: "ES", name: "ACAB", phone: "93 454 91 09", dial: "+34934549109",
                 url: URL(string: "https://www.acab.org/")!,
                 note: String(localized: "Association against Anorexia and Bulimia, Barcelona. Weekday phone and email advice.")),
        Helpline(region: "IT", name: "SOS Disturbi Alimentari", phone: "800 180 969", dial: "800180969",
                 url: URL(string: "https://sosdisturbialimentari.it/")!,
                 note: String(localized: "National freephone, Monday to Friday 9:00–21:00.")),
        Helpline(region: "NL", name: "Proud2Bme", url: URL(string: "https://www.proud2bme.nl/")!,
                 note: String(localized: "Online chat every evening 19:00–21:00, and a forum.")),
        Helpline(region: "", name: "Find A Helpline", url: URL(string: "https://findahelpline.com/")!,
                 note: String(localized: "A free directory of helplines in many more countries; choose Eating & body image.")),
    ]
}
