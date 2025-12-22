declare module 'lightning/navigation' {
    /**
     * Represents a PageReference object used for navigation
     */
    export interface PageReference {
        type: string;
        attributes: { [key: string]: any };
        state?: { [key: string]: any };
    }

    /**
     * The NavigationMixin function
     */
    export function NavigationMixin<T>(Base: T): T;

    /**
     * Static properties on the NavigationMixin function
     * used to access the navigation methods on the component instance
     */
    export namespace NavigationMixin {
        export const Navigate: string;
        export const GenerateUrl: string;
    }

    /**
     * Wire adapter for current page reference
     */
    export const CurrentPageReference: any;
}