import Vue from 'vue';
import { createStore } from '~/ide/stores';
import Bar from '~/ide/components/file_templates/bar.vue';
import { createComponentWithStore } from 'spec/helpers/vue_mount_component_helper';
import { resetStore, file } from '../../helpers';

describe('IDE file templates bar component', () => {
  let Component;
  let vm;

  beforeAll(() => {
    Component = Vue.extend(Bar);
  });

  beforeEach(() => {
    const store = createStore();

    store.state.openFiles.push({
      ...file('file'),
      opened: true,
      active: true,
    });

    vm = createComponentWithStore(Component, store).$mount();
  });

  afterEach(() => {
    vm.$destroy();
    resetStore(vm.$store);
  });

  describe('template type dropdown', () => {
    it('renders dropdown component', () => {
      expect(vm.$el.querySelector('.dropdown').textContent).toContain('Choose a type');
    });

    it('calls setSelectedTemplateType when clicking item', () => {
      spyOn(vm, 'setSelectedTemplateType');

      vm.$el.querySelector('.dropdown-content button').click();

      expect(vm.setSelectedTemplateType).toHaveBeenCalledWith({
        name: '.gitlab-ci.yml',
        key: 'gitlab_ci_ymls',
      });
    });
  });

  describe('template dropdown', () => {
    beforeEach(done => {
      vm.$store.state.fileTemplates.templates = [
        {
          name: 'test',
        },
      ];
      vm.$store.state.fileTemplates.selectedTemplateType = {
        name: '.gitlab-ci.yml',
        key: 'gitlab_ci_ymls',
      };

      vm.$nextTick(done);
    });

    it('renders dropdown component', () => {
      expect(vm.$el.querySelectorAll('.dropdown')[1].textContent).toContain('Choose a template');
    });

    it('calls fetchTemplate on click', () => {
      spyOn(vm, 'fetchTemplate');

      vm.$el
        .querySelectorAll('.dropdown-content')[1]
        .querySelector('button')
        .click();

      expect(vm.fetchTemplate).toHaveBeenCalledWith({
        name: 'test',
      });
    });
  });

  it('shows undo button if updateSuccess is true', done => {
    vm.$store.state.fileTemplates.updateSuccess = true;

    vm.$nextTick(() => {
      expect(vm.$el.querySelector('.btn-default').style.display).not.toBe('none');

      done();
    });
  });

  it('calls undoFileTemplate when clicking undo button', () => {
    spyOn(vm, 'undoFileTemplate');

    vm.$el.querySelector('.btn-default').click();

    expect(vm.undoFileTemplate).toHaveBeenCalled();
  });

  it('calls setSelectedTemplateType if activeFile name matches a template', done => {
    spyOn(vm, 'setSelectedTemplateType');
    vm.$store.state.openFiles[0].name = '.gitlab-ci.yml';

    vm.setInitialType();

    vm.$nextTick(() => {
      expect(vm.setSelectedTemplateType).toHaveBeenCalledWith({
        name: '.gitlab-ci.yml',
        key: 'gitlab_ci_ymls',
      });

      done();
    });
  });
});
