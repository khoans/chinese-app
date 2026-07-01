/* ============================================================================
 * data/registry.js — Bộ gom dữ liệu HSK (NẠP ĐẦU TIÊN, trước manifest & các cấp)
 * ----------------------------------------------------------------------------
 * Mỗi file cấp tự sinh (data/<LEVEL>/<level>.js) gọi registerLevel(...) để nạp
 * từ vựng + hội thoại của cấp đó vào một bộ sưu tập toàn cục "HSKData".
 * App đọc dữ liệu qua HSKData.words() / conversations() / levels() / topics()
 * thay cho các mảng WORDS/CONVS/TOPICS nhúng cứng ngày xưa.
 *
 * CHẠY ĐƯỢC TRÊN file:// — chỉ dùng thẻ <script>, không fetch, không ES module.
 * ==========================================================================*/
(function (globalScope) {
  "use strict";

  // Kho nội bộ: giữ nguyên thứ tự cấp được đăng ký (build ghi manifest đúng thứ tự).
  var registeredLevels = [];          // ["HSK1","HSK2",...]
  var wordsByLevel = {};              // { HSK1: [word,...], ... }
  var conversationsByLevel = {};      // { HSK1: [conv,...], ... }
  var sentencesByLevel = {};          // { HSK1: [sentence,...], ... } — câu độc lập cho chế độ Dịch câu

  /**
   * registerLevel — mỗi file cấp tự sinh gọi hàm này đúng một lần.
   * @param {string} level  Ví dụ "HSK1".
   * @param {{words:Array, conversations:Array, sentences:Array}} payload
   *   Mỗi từ: { w, p, m, ex, exp, exm, topic }  (KHÔNG cần "lv" — tự gắn ở đây)
   *   Mỗi hội thoại: { title, icon, lines:[{who,zh,py,vi}] }
   *   Mỗi câu độc lập: { zh, py, vi, topic }  (cho chế độ Dịch câu; KHÔNG cần "lv")
   */
  function registerLevel(level, payload) {
    payload = payload || {};
    if (registeredLevels.indexOf(level) === -1) registeredLevels.push(level);

    // Gắn cấp vào từng từ để app lọc theo cấp như cũ (w.lv).
    var levelWords = (payload.words || []).map(function (word) {
      var copy = {};
      for (var key in word) if (Object.prototype.hasOwnProperty.call(word, key)) copy[key] = word[key];
      copy.lv = level;
      return copy;
    });
    wordsByLevel[level] = levelWords;

    // Gắn cấp vào hội thoại để chế độ dịch câu có thể lọc theo cấp.
    var levelConversations = (payload.conversations || []).map(function (conv) {
      var copy = {};
      for (var key in conv) if (Object.prototype.hasOwnProperty.call(conv, key)) copy[key] = conv[key];
      copy.lv = level;
      return copy;
    });
    conversationsByLevel[level] = levelConversations;

    // Câu độc lập (sentences.csv) — gắn cấp để chế độ Dịch câu lọc được theo cấp.
    var levelSentences = (payload.sentences || []).map(function (sentence) {
      var copy = {};
      for (var key in sentence) if (Object.prototype.hasOwnProperty.call(sentence, key)) copy[key] = sentence[key];
      copy.lv = level;
      return copy;
    });
    sentencesByLevel[level] = levelSentences;
  }

  var HSKData = {
    /** Danh sách cấp theo thứ tự đăng ký, ví dụ ["HSK1","HSK2"]. */
    levels: function () {
      return registeredLevels.slice();
    },

    /** Tất cả từ vựng (đã gắn w.lv), gộp theo thứ tự cấp. */
    words: function () {
      var all = [];
      registeredLevels.forEach(function (level) {
        var list = wordsByLevel[level] || [];
        for (var i = 0; i < list.length; i++) all.push(list[i]);
      });
      return all;
    },

    /** Tất cả hội thoại (đã gắn conv.lv), gộp theo thứ tự cấp. */
    conversations: function () {
      var all = [];
      registeredLevels.forEach(function (level) {
        var list = conversationsByLevel[level] || [];
        for (var i = 0; i < list.length; i++) all.push(list[i]);
      });
      return all;
    },

    /** Tất cả câu độc lập (đã gắn sentence.lv), gộp theo thứ tự cấp — cho chế độ Dịch câu. */
    sentences: function () {
      var all = [];
      registeredLevels.forEach(function (level) {
        var list = sentencesByLevel[level] || [];
        for (var i = 0; i < list.length; i++) all.push(list[i]);
      });
      return all;
    },

    /**
     * Danh sách chủ đề — TỰ SUY RA từ trường "topic" của từ vựng,
     * giữ đúng thứ tự xuất hiện lần đầu. Người biên soạn chỉ cần gõ tên chủ đề
     * vào cột "chuDe" của CSV, không phải khai báo danh sách ở đâu khác.
     */
    topics: function () {
      var seen = {};
      var order = [];
      HSKData.words().forEach(function (word) {
        var topic = word.topic;
        if (topic && !seen[topic]) { seen[topic] = true; order.push(topic); }
      });
      return order;
    }
  };

  // Ghi ra cả window (trang) lẫn self/globalThis (service worker nếu có) đều đọc được.
  globalScope.registerLevel = registerLevel;
  globalScope.HSKData = HSKData;
})(typeof self !== "undefined" ? self : this);
