/* global Vue */
/* global ListIssue */
//= require ./header
//= require ./list
//= require ./footer
//= require ./empty_state
(() => {
  const ModalStore = gl.issueBoards.ModalStore;

  gl.issueBoards.IssuesModal = Vue.extend({
    props: {
      blankStateImage: {
        type: String,
        required: true,
      },
      newIssuePath: {
        type: String,
        required: true,
      },
      issueLinkBase: {
        type: String,
        required: true,
      },
      rootPath: {
        type: String,
        required: true,
      },
      projectId: {
        type: Number,
        required: true,
      },
    },
    data() {
      return ModalStore.store;
    },
    watch: {
      page() {
        this.loadIssues();
      },
      searchTerm() {
        this.searchOperation();
      },
      showAddIssuesModal() {
        if (this.showAddIssuesModal && !this.issues.length) {
          this.loading = true;

          this.loadIssues()
            .then(() => {
              this.loading = false;
            });
        } else if (!this.showAddIssuesModal) {
          this.issues = [];
          this.selectedIssues = [];
          this.issuesCount = false;
        }
      },
      filter: {
        handler() {
          this.loadIssues(true);
        },
        deep: true,
      }
    },
    methods: {
      searchOperation: _.debounce(function searchOperationDebounce() {
        this.loadIssues(true);
      }, 500),
      loadIssues(clearIssues = false) {
        const data = Object.assign({}, this.filter, {
          search: this.searchTerm,
          page: this.page,
          per: this.perPage,
        });

        return gl.boardService.getBacklog(data).then((res) => {
          const data = res.json();

          if (clearIssues) {
            this.issues = [];
          }

          data.issues.forEach((issueObj) => {
            const issue = new ListIssue(issueObj);
            const foundSelectedIssue = ModalStore.findSelectedIssue(issue);
            issue.selected = !!foundSelectedIssue;

            this.issues.push(issue);
          });

          this.loadingNewPage = false;

          if (!this.issuesCount) {
            this.issuesCount = data.size;
          }
        });
      },
    },
    computed: {
      showList() {
        if (this.activeTab === 'selected') {
          return this.selectedIssues.length > 0;
        }

        return this.issuesCount > 0;
      },
      showEmptyState() {
        if (!this.loading && this.issuesCount === 0) {
          return true;
        }

        return this.activeTab === 'selected' && this.selectedIssues.length === 0;
      },
    },
    components: {
      'modal-header': gl.issueBoards.ModalHeader,
      'modal-list': gl.issueBoards.ModalList,
      'modal-footer': gl.issueBoards.ModalFooter,
      'empty-state': gl.issueBoards.ModalEmptyState,
    },
    template: `
      <div
        class="add-issues-modal"
        v-if="showAddIssuesModal">
        <div class="add-issues-container">
          <modal-header
            :project-id="projectId">
          </modal-header>
          <modal-list
            :issue-link-base="issueLinkBase"
            :root-path="rootPath"
            v-if="!loading && showList"></modal-list>
          <empty-state
            v-if="showEmptyState"
            :image="blankStateImage"
            :new-issue-path="newIssuePath"></empty-state>
          <section
            class="add-issues-list text-center"
            v-if="loading">
            <div class="add-issues-list-loading">
              <i class="fa fa-spinner fa-spin"></i>
            </div>
          </section>
          <modal-footer></modal-footer>
        </div>
      </div>
    `,
  });
})();
