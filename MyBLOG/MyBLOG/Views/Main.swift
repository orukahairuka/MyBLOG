
import SwiftUI

struct MainView: View {
    let apiClient: NotionApiClient
    @State var selection = 1

    init(apiClient: NotionApiClient) {
            self.apiClient = apiClient
            UITabBar.appearance().backgroundColor = .white
        }

    var body: some View {

        TabView(selection: $selection) {
            SelfIntroductionView()
                .tabItem {
                    Label("about me", systemImage: "face.smiling")
                }
                .tag(1)

            DatabaseListView(viewModel: ArticleDatabase(apiClient: apiClient), databaseId: "c5a35870426c49f0b7669991b1c92fa6")
                .tabItem {
                    Label("article", systemImage: "newspaper")
                }
                .tag(2)

            AdressView()
                .tabItem {
                    Label("address", systemImage: "house")
                }
                .tag(3)
        }
    }
}
