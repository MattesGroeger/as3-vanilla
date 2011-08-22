package org.osflash.vanilla.reflection.as3commons
{
	import org.as3commons.reflect.Metadata;
	import org.as3commons.reflect.MetadataArgument;
	import org.osflash.vanilla.reflection.AnnotationError;
	
	public class MetadataProvider
	{
		private static const EMPTY : Vector.<MetadataArgument> = new Vector.<MetadataArgument>(0, true);
		
		protected const _metadataArgumentsByTagName : Object = {};

		public function MetadataProvider(metadatas : Vector.<Metadata>) 
		{
			if (metadatas) {
				populateMap(metadatas);
			}
		}

		private function populateMap(tags : Vector.<Metadata>) : void
		{
			const numTags : uint = tags.length;
			for (var i : uint = 0; i < numTags; i++) {
				if (_metadataArgumentsByTagName[tags[i].name] !== undefined) {
					throw new AnnotationError("Vanilla does not support annotating mutliple metadata tags on a given field or method.  Found more than on occurance of " + tags[i], AnnotationError.MULTIPLE_ANNOTATIONS);
				}
				
				_metadataArgumentsByTagName[tags[i].name] = tags[i].arguments;
			}
		}
		
		/**
		 * Retrieves the MetadataArguments for the supplied tagName.  If there is no MetadataTag that matches the
		 * supplied name then an empty list will be returned.  Note that Vanilla does not support annotating
		 * more than one MetadataTag on a given method or field.
		 */
		public function getMetadataArguments(tagName : String) : Vector.<MetadataArgument> 
		{
			if (_metadataArgumentsByTagName[tagName]) {
				return _metadataArgumentsByTagName[tagName];
			}
			return EMPTY;
		}		
	}
}
