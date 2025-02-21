<script>
import Draggable from 'vuedraggable';
import { s__ } from '~/locale';
import { setCookie, getCookie } from '~/lib/utils/common_utils';
import { SIDEBAR_PINS_EXPANDED_COOKIE, SIDEBAR_COOKIE_EXPIRATION } from '../constants';
import MenuSection from './menu_section.vue';
import NavItem from './nav_item.vue';

const AMBIGUOUS_SETTINGS = {
  ci_cd: s__('Navigation|CI/CD settings'),
  merge_request_settings: s__('Navigation|Merge requests settings'),
  monitor: s__('Navigation|Monitor settings'),
  repository: s__('Navigation|Repository settings'),
};

export default {
  i18n: {
    pinned: s__('Navigation|Pinned'),
    emptyHint: s__('Navigation|Your pinned items appear here.'),
  },
  name: 'PinnedSection',
  components: {
    Draggable,
    MenuSection,
    NavItem,
  },
  props: {
    items: {
      type: Array,
      required: false,
      default: () => [],
    },
    hasFlyout: {
      type: Boolean,
      required: false,
      default: false,
    },
  },
  data() {
    return {
      expanded: getCookie(SIDEBAR_PINS_EXPANDED_COOKIE) !== 'false',
      draggableItems: this.renameSettings(this.items),
    };
  },
  computed: {
    isActive() {
      return this.items.some((item) => item.is_active);
    },
    sectionItem() {
      return {
        title: this.$options.i18n.pinned,
        icon: 'thumbtack',
        is_active: this.isActive,
        items: this.draggableItems,
      };
    },
    itemIds() {
      return this.draggableItems.map((item) => item.id);
    },
  },
  watch: {
    expanded(newExpanded) {
      setCookie(SIDEBAR_PINS_EXPANDED_COOKIE, newExpanded, {
        expires: SIDEBAR_COOKIE_EXPIRATION,
      });
    },
    items(newItems) {
      this.draggableItems = this.renameSettings(newItems);
    },
  },
  methods: {
    handleDrag(event) {
      if (event.oldIndex === event.newIndex) return;
      this.$emit(
        'pin-reorder',
        this.items[event.oldIndex].id,
        this.items[event.newIndex].id,
        event.oldIndex < event.newIndex,
      );
    },
    renameSettings(items) {
      return items.map((i) => {
        const title = AMBIGUOUS_SETTINGS[i.id] || i.title;
        return { ...i, title };
      });
    },
    onPinRemove(itemId, itemTitle) {
      this.$emit('pin-remove', itemId, itemTitle);
    },
  },
};
</script>

<template>
  <menu-section
    :item="sectionItem"
    :expanded="expanded"
    :has-flyout="hasFlyout"
    @collapse-toggle="expanded = !expanded"
    @pin-remove="onPinRemove"
  >
    <draggable
      v-if="items.length > 0"
      v-model="draggableItems"
      class="gl-p-0 gl-m-0 gl-list-style-none"
      data-testid="pinned-nav-items"
      handle=".js-draggable-icon"
      tag="ul"
      @end="handleDrag"
    >
      <nav-item
        v-for="item of draggableItems"
        :key="item.id"
        :item="item"
        is-in-pinned-section
        @pin-remove="onPinRemove(item.id, item.title)"
      />
    </draggable>
    <li
      v-else
      class="gl-text-secondary gl-font-sm gl-py-3 super-sidebar-empty-pinned-text"
      style="margin-left: 2.5rem"
    >
      {{ $options.i18n.emptyHint }}
    </li>
  </menu-section>
</template>
