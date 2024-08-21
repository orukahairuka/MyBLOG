
import SwiftUI

struct MainView: View {
    let apiClient: NotionApiClient
    @State var selection = 1

    var body: some View {

        TabView(selection: $selection) {
            My_introduceView()
                .tabItem {
                    Label("Page1", systemImage: "1.circle")
                }
                .tag(1)

            DatabaseListView(viewModel: ArticleDatabase(apiClient: apiClient), databaseId: "c5a35870426c49f0b7669991b1c92fa6")
                .tabItem {
                    Label("Page2", systemImage: "2.circle")
                }
                .tag(2)

            AdressView()
                .tabItem {
                    Label("Page3", systemImage: "3.circle")
                }
                .tag(3)
        }
    }
}
